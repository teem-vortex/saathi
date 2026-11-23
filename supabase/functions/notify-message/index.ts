import { createClient } from 'npm:@supabase/supabase-js@2';
import { GoogleAuth } from 'npm:google-auth-library@9';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  } });
  const cors = { 'Access-Control-Allow-Origin': '*' };
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const authorization = request.headers.get('Authorization');
  if (!authorization) return new Response('Unauthorized', { status: 401 });
  const url = Deno.env.get('SUPABASE_URL')!;
  const client = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: { user } } = await client.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });
  let messageId: unknown;
  try { messageId = (await request.json()).message_id; } catch { return new Response('Invalid request', { status: 400 }); }
  if (typeof messageId !== 'string' || !/^[0-9a-f-]{36}$/i.test(messageId)) return new Response('Invalid message', { status: 400 });
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: message } = await admin.from('messages').select('sender_id, pairing_id').eq('id', messageId).maybeSingle();
  if (!message || message.sender_id !== user.id) return new Response('Not found', { status: 404 });
  const { data: pairing } = await admin.from('pairings').select('primary_id, guardian_id, status').eq('id', message.pairing_id).maybeSingle();
  if (!pairing || pairing.status !== 'accepted' || ![pairing.primary_id, pairing.guardian_id].includes(user.id)) return new Response('Not found', { status: 404 });
  const recipient = pairing.primary_id === user.id ? pairing.guardian_id : pairing.primary_id;
  const { data: tokens, error } = await admin.from('push_tokens').select('token').eq('user_id', recipient);
  if (error) return new Response('Notification unavailable', { status: 503 });
  try {
    const credentials = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!);
    const auth = new GoogleAuth({ credentials, scopes: ['https://www.googleapis.com/auth/firebase.messaging'] });
    const accessToken = await auth.getAccessToken();
    const results = await Promise.all((tokens ?? []).map(({ token }) => fetch(
      `https://fcm.googleapis.com/v1/projects/${credentials.project_id}/messages:send`,
      { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: { token, notification: { title: 'Saathi', body: 'You have a new message in Saathi.' }, data: { message_id: messageId } } }) },
    )));
    if (results.some((result) => !result.ok)) return new Response('Some notifications could not be sent', { status: 502 });
    return Response.json({ attempted: results.length }, { headers: cors });
  } catch { return new Response('Notification unavailable', { status: 503 }); }
});
