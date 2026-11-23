let activeRecognizer;
window.saathiVoice = async (method, lang, text) => {
  if (method === 'stopListening') { activeRecognizer?.stop(); return ''; }
  if (method === 'stopSpeaking') { window.speechSynthesis?.cancel(); return ''; }
  if (method === 'speak') {
    if (!window.speechSynthesis) throw Error('Read aloud is unavailable in this browser.');
    const line = new SpeechSynthesisUtterance(text);
    line.lang = lang;
    speechSynthesis.cancel();
    return new Promise((resolve, reject) => {
      line.onend = () => resolve('');
      line.onerror = e => reject(Error(e.error));
      speechSynthesis.speak(line);
    });
  }
  const Recognizer = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!Recognizer) throw Error('Dictation is unavailable. Please type your draft.');
  return new Promise((resolve, reject) => {
    const mic = new Recognizer();
    activeRecognizer = mic;
    mic.lang = lang;
    let transcript = '';
    mic.continuous = false;
    mic.interimResults = false;
    mic.onresult = e => {
      transcript = Array.from(e.results)
        .filter(result => result.isFinal)
        .map(result => result[0].transcript.trim())
        .filter(Boolean)
        .join(' ');
    };
    mic.onerror = e => { activeRecognizer = null; reject(Error(e.error)); };
    mic.onend = () => { activeRecognizer = null; resolve(transcript); };
    mic.start();
  });
};
