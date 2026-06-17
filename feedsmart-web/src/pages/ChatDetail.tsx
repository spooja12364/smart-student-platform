import { useState, useEffect, useRef } from 'react';
import { useParams } from 'react-router-dom';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, doc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, auth, storage } from '../firebase';
import { Send, Image as ImageIcon, Mic, Square } from 'lucide-react';

export default function ChatDetail() {
  const { chatId } = useParams();
  const [messages, setMessages] = useState<any[]>([]);
  const [text, setText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [uploading, setUploading] = useState(false);
  
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!chatId) return;
    const q = query(
      collection(db, 'chats', chatId, 'messages'),
      orderBy('timestamp', 'asc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setMessages(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setTimeout(() => scrollRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    });
    return () => unsubscribe();
  }, [chatId]);

  const sendMessage = async (messageData: any) => {
    if (!chatId || !auth.currentUser) return;
    
    await addDoc(collection(db, 'chats', chatId, 'messages'), {
      senderId: auth.currentUser.uid,
      timestamp: serverTimestamp(),
      ...messageData
    });

    await setDoc(doc(db, 'chats', chatId), {
      lastMessage: messageData.text || (messageData.imageUrl ? '📷 Photo' : '🎤 Voice Note'),
      lastUpdated: serverTimestamp(),
    }, { merge: true });
  };

  const handleSendText = () => {
    if (!text.trim()) return;
    sendMessage({ text });
    setText('');
  };

  const handleImageUpload = async (e: any) => {
    const file = e.target.files?.[0];
    if (!file || !chatId) return;
    
    setUploading(true);
    try {
      const storageRef = ref(storage, `chat_images/${chatId}/${Date.now()}_${file.name}`);
      await uploadBytes(storageRef, file);
      const imageUrl = await getDownloadURL(storageRef);
      await sendMessage({ imageUrl });
    } catch (err) {
      console.error(err);
      alert('Failed to upload image');
    } finally {
      setUploading(false);
    }
  };

  const toggleRecording = async () => {
    if (isRecording) {
      mediaRecorderRef.current?.stop();
      setIsRecording(false);
    } else {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const mediaRecorder = new MediaRecorder(stream);
        mediaRecorderRef.current = mediaRecorder;
        audioChunksRef.current = [];

        mediaRecorder.ondataavailable = (event) => {
          if (event.data.size > 0) audioChunksRef.current.push(event.data);
        };

        mediaRecorder.onstop = async () => {
          const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
          if (audioBlob.size > 0) {
            setUploading(true);
            try {
              const storageRef = ref(storage, `chat_audio/${chatId}/${Date.now()}.webm`);
              await uploadBytes(storageRef, audioBlob);
              const audioUrl = await getDownloadURL(storageRef);
              await sendMessage({ audioUrl });
            } catch (err) {
              console.error(err);
              alert('Failed to send voice note');
            } finally {
              setUploading(false);
            }
          }
          stream.getTracks().forEach(track => track.stop());
        };

        mediaRecorder.start();
        setIsRecording(true);
      } catch (err) {
        console.error(err);
        alert('Microphone access denied');
      }
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-120px)] bg-card/40 backdrop-blur-xl border border-border/50 rounded-2xl shadow-lg shadow-black/5 overflow-hidden animate-in fade-in zoom-in-95 duration-500">
      <div className="p-4 border-b border-border/50 bg-secondary/30 backdrop-blur-md">
        <h3 className="font-bold text-lg">Chat</h3>
      </div>
      
      <div className="flex-1 p-6 overflow-y-auto space-y-4">
        {messages.map((m, i) => {
          const isMe = m.senderId === auth.currentUser?.uid;
          return (
            <div key={m.id || i} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[70%] p-4 rounded-2xl ${isMe ? 'bg-primary text-primary-foreground rounded-tr-sm' : 'bg-secondary text-secondary-foreground rounded-tl-sm shadow-md'}`}>
                {m.text && <p className="text-sm">{m.text}</p>}
                {m.imageUrl && <img src={m.imageUrl} alt="uploaded" className="max-w-full rounded-lg mt-2" />}
                {m.audioUrl && (
                  <audio controls className="mt-2 h-10">
                    <source src={m.audioUrl} type="audio/webm" />
                    <source src={m.audioUrl} type="audio/mp4" />
                    <source src={m.audioUrl} type="audio/m4a" />
                  </audio>
                )}
              </div>
            </div>
          );
        })}
        <div ref={scrollRef} />
      </div>

      <div className="p-4 border-t border-border/50 bg-card/80 backdrop-blur-md">
        {uploading && <div className="text-xs text-primary mb-2 font-medium animate-pulse">Uploading media...</div>}
        <div className="flex items-center space-x-2">
          <label className="p-3 rounded-xl bg-secondary/50 hover:bg-secondary cursor-pointer transition-colors text-muted-foreground hover:text-foreground">
            <ImageIcon className="w-5 h-5" />
            <input type="file" accept="image/*" className="hidden" onChange={handleImageUpload} />
          </label>
          <button 
            onClick={toggleRecording} 
            className={`p-3 rounded-xl transition-all ${isRecording ? 'bg-red-500/20 text-red-500 animate-pulse' : 'bg-secondary/50 hover:bg-secondary text-muted-foreground hover:text-foreground'}`}
          >
            {isRecording ? <Square className="w-5 h-5 fill-current" /> : <Mic className="w-5 h-5" />}
          </button>
          <input
            type="text"
            className="flex-1 bg-secondary/50 border border-border/50 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all text-sm"
            placeholder="Type your message..."
            value={text}
            onChange={e => setText(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleSendText()}
          />
          <button 
            onClick={handleSendText}
            className="p-3 rounded-xl bg-primary text-primary-foreground hover:bg-primary/90 transition-transform hover:scale-105 active:scale-95 shadow-lg shadow-primary/20"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
