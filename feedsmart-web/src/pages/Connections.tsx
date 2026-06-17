import { useEffect, useState } from 'react';
import { collection, query, getDocs, doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db, auth } from '../firebase';
import { User, UserPlus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function Connections() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const handleConnect = async (targetUser: any) => {
    if (!auth.currentUser) {
      alert("Please login first to connect.");
      return;
    }
    
    // Create a unique chat ID using both user IDs
    const chatIds = [auth.currentUser.uid, targetUser.id].sort();
    const chatId = `chat_${chatIds[0]}_${chatIds[1]}`;
    
    try {
      await setDoc(doc(db, 'chats', chatId), {
        participants: [auth.currentUser.uid, targetUser.id],
        name: targetUser.name || targetUser.username || 'Student',
        lastUpdated: serverTimestamp(),
      }, { merge: true });
      
      navigate(`/dashboard/chats/${chatId}`);
    } catch (e) {
      console.error(e);
      alert("Failed to start chat.");
    }
  };

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        // Query users collection
        const q = query(collection(db, 'users'));
        const querySnapshot = await getDocs(q);
        const usersData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const otherUsers = usersData.filter((u: any) => u.id !== auth?.currentUser?.uid);
        setUsers(otherUsers.length > 0 ? otherUsers : getMockUsers());
      } catch (e) {
        console.error(e);
        setUsers(getMockUsers());
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-700">
      <h2 className="text-3xl font-extrabold mb-8 tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">
        Discover Connections
      </h2>

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {users.map((u, i) => (
            <div key={u.id || i} className="bg-card/40 backdrop-blur-xl border border-border/50 rounded-2xl p-6 shadow-lg shadow-black/5 hover:shadow-primary/10 transition-all hover:-translate-y-1 flex flex-col group">
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-14 h-14 rounded-full bg-gradient-to-br from-gray-700 to-gray-600 flex items-center justify-center shadow-inner group-hover:scale-105 transition-transform">
                  <User className="w-6 h-6 text-gray-300" />
                </div>
                <div>
                  <h3 className="font-bold text-lg group-hover:text-primary transition-colors">{u.name || u.username || 'Student'}</h3>
                  <p className="text-sm text-muted-foreground line-clamp-1">{u.bio || 'Computer Science Student'}</p>
                </div>
              </div>
              
              <div className="mt-auto pt-4 border-t border-border/50 flex items-center justify-between">
                <div className="flex flex-wrap gap-2">
                  <span className="px-2 py-1 bg-primary/10 text-primary text-xs rounded-md">React</span>
                  <span className="px-2 py-1 bg-primary/10 text-primary text-xs rounded-md">Node</span>
                </div>
                <button 
                  onClick={() => handleConnect(u)}
                  className="p-2 rounded-xl bg-primary text-primary-foreground hover:bg-primary/90 transition-colors shadow-lg shadow-primary/20 hover:scale-105 active:scale-95"
                >
                  <UserPlus className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function getMockUsers() {
  return [
    { id: '1', name: 'Alice Smith', bio: 'AI Researcher & Python Enthusiast' },
    { id: '2', name: 'Bob Jones', bio: 'Fullstack Web Developer' },
    { id: '3', name: 'Charlie Davis', bio: 'UI/UX Designer building beautiful interfaces' },
    { id: '4', name: 'Diana Prince', bio: 'Data Science Student' },
    { id: '5', name: 'Evan Wright', bio: 'Mobile App Developer' },
    { id: '6', name: 'Fiona Gallagher', bio: 'Cloud Architect & DevOps' },
  ];
}
