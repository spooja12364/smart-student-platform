import { useEffect, useState } from 'react';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { db, auth } from '../firebase';
import { MessageSquare, User } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function ChatList() {
  const [chats, setChats] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchChats = async () => {
      if (!auth.currentUser) {
        setChats(getMockChats());
        setLoading(false);
        return;
      }

      try {
        const q = query(
          collection(db, 'chats'),
          where('participants', 'array-contains', auth.currentUser.uid)
        );
        const querySnapshot = await getDocs(q);
        const chatsData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        setChats(chatsData.length > 0 ? chatsData : getMockChats());
      } catch (e) {
        console.error(e);
        setChats(getMockChats());
      } finally {
        setLoading(false);
      }
    };
    fetchChats();
  }, []);

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-700">
      <h2 className="text-3xl font-extrabold mb-8 tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">
        Your Conversations
      </h2>

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="bg-card/40 backdrop-blur-xl border border-border/50 rounded-2xl overflow-hidden shadow-lg shadow-black/5">
          {chats.map((chat, i) => (
            <div 
              key={chat.id || i}
              onClick={() => navigate(`/dashboard/chats/${chat.id}`)}
              className="flex items-center space-x-4 p-5 border-b border-border/50 hover:bg-secondary/40 transition-colors cursor-pointer group"
            >
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500 to-primary flex items-center justify-center shadow-inner group-hover:scale-105 transition-transform">
                <User className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="font-bold text-lg group-hover:text-primary transition-colors">
                  {chat.name || 'Chat Partner'}
                </h3>
                <p className="text-sm text-muted-foreground truncate">
                  {chat.lastMessage || 'Tap to start messaging...'}
                </p>
              </div>
              <div className="text-xs text-muted-foreground font-medium">
                {chat.lastUpdated?.toDate ? chat.lastUpdated.toDate().toLocaleDateString() : 'Just now'}
              </div>
            </div>
          ))}
          {chats.length === 0 && (
            <div className="p-10 text-center text-muted-foreground flex flex-col items-center">
              <MessageSquare className="w-12 h-12 mb-4 opacity-50" />
              <p>No conversations yet. Start connecting!</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function getMockChats() {
  return [
    { id: 'chat_1', name: 'Alice Smith', lastMessage: 'Hey, do you want to collaborate on the React project?' },
    { id: 'chat_2', name: 'Bob Jones', lastMessage: 'I sent you the Python script.' },
  ];
}
