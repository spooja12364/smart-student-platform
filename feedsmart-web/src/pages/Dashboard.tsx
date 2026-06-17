import React from 'react';
import { Routes, Route, Link, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, MessageSquare, Bell, User, Settings, LogOut, Code } from 'lucide-react';
import { auth } from '../firebase';
import { signOut } from 'firebase/auth';

import Connections from './Connections';
import ChatList from './ChatList';
import ChatDetail from './ChatDetail';

export default function Dashboard() {
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/login');
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="min-h-screen bg-background flex overflow-hidden">
      {/* Sidebar - Premium Glassmorphism */}
      <aside className="w-64 border-r border-border/50 bg-card/40 backdrop-blur-2xl hidden md:flex flex-col relative z-20">
        <div className="absolute inset-0 bg-gradient-to-b from-primary/5 to-transparent pointer-events-none" />
        
        <div className="p-6 flex items-center space-x-3 border-b border-border/50 relative">
          <div className="h-10 w-10 bg-gradient-to-br from-primary to-purple-600 rounded-xl flex items-center justify-center shadow-lg shadow-primary/20 transform rotate-3 transition-transform hover:rotate-6 hover:scale-105">
            <Users className="text-white w-6 h-6 -rotate-3" />
          </div>
          <span className="font-extrabold text-2xl tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">FeedSmart</span>
        </div>
        
        <nav className="flex-1 p-4 space-y-2 relative">
          <NavItem icon={<LayoutDashboard />} label="Home" to="/dashboard" active={location.pathname === '/dashboard'} />
          <NavItem icon={<Users />} label="Connections" to="/dashboard/connections" active={location.pathname.includes('/connections')} />
          <NavItem icon={<MessageSquare />} label="Chats" to="/dashboard/chats" active={location.pathname.includes('/chats')} />
          
          <div className="pt-4 mt-4 border-t border-border/50">
            <p className="px-3 text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">More</p>
            <NavItem icon={<Code />} label="Skills" to="#" />
            <NavItem icon={<Bell />} label="Notifications" to="#" />
            <NavItem icon={<User />} label="Profile" to="#" />
            <NavItem icon={<Settings />} label="Settings" to="#" />
          </div>
        </nav>
        
        <div className="p-4 border-t border-border/50 relative">
          <button onClick={handleLogout} className="flex items-center space-x-3 text-red-400 hover:text-red-300 hover:bg-red-500/10 w-full p-3 rounded-xl transition-all font-medium">
            <LogOut className="w-5 h-5" />
            <span>Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 overflow-auto relative bg-gradient-to-br from-background to-card/20">
        <div className="absolute top-0 left-0 w-[500px] h-[500px] bg-primary/10 rounded-full mix-blend-screen filter blur-[100px] opacity-30 pointer-events-none" />
        <div className="absolute bottom-0 right-0 w-[500px] h-[500px] bg-purple-500/10 rounded-full mix-blend-screen filter blur-[100px] opacity-30 pointer-events-none" />
        
        <header className="h-16 border-b border-border/50 bg-card/30 backdrop-blur-md flex items-center justify-between px-8 sticky top-0 z-10">
          <h2 className="font-bold text-xl tracking-tight">Dashboard</h2>
          <div className="flex items-center space-x-5">
            <button className="relative p-2 rounded-full hover:bg-secondary/80 transition-colors">
              <Bell className="w-5 h-5 text-muted-foreground hover:text-white transition-colors" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full shadow-[0_0_8px_rgba(239,68,68,0.8)] animate-pulse"></span>
            </button>
            <div className="h-9 w-9 rounded-full bg-gradient-to-br from-primary to-purple-600 p-[2px] cursor-pointer hover:scale-105 transition-transform">
              <div className="h-full w-full rounded-full bg-card flex items-center justify-center overflow-hidden">
                <User className="w-5 h-5 text-primary" />
              </div>
            </div>
          </div>
        </header>
        
        <div className="p-8 relative z-0">
          <Routes>
            <Route path="/" element={<DashboardHome />} />
            <Route path="/connections" element={<Connections />} />
            <Route path="/chats" element={<ChatList />} />
            <Route path="/chats/:chatId" element={<ChatDetail />} />
          </Routes>
        </div>
      </main>
    </div>
  );
}

function DashboardHome() {
  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <StatCard label="Skills Count" value="5" icon={<Code className="w-6 h-6 text-blue-400" />} />
        <StatCard label="Connections" value="12" icon={<Users className="w-6 h-6 text-green-400" />} />
        <StatCard label="Active Chats" value="3" icon={<MessageSquare className="w-6 h-6 text-purple-400" />} />
        <StatCard label="Profile Score" value="92%" icon={<User className="w-6 h-6 text-orange-400" />} />
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-card/40 backdrop-blur-xl border border-border/50 rounded-2xl p-7 shadow-lg shadow-black/5">
          <h3 className="font-bold text-xl mb-6 flex items-center">
            <span className="bg-primary/20 text-primary p-2 rounded-lg mr-3">
              <Code className="w-5 h-5" />
            </span>
            Trending Skills
          </h3>
          <div className="flex flex-wrap gap-3">
            <span className="px-4 py-2 bg-secondary/80 hover:bg-secondary text-secondary-foreground rounded-xl text-sm font-medium transition-colors cursor-pointer border border-border/50">React (High Demand)</span>
            <span className="px-4 py-2 bg-secondary/80 hover:bg-secondary text-secondary-foreground rounded-xl text-sm font-medium transition-colors cursor-pointer border border-border/50">Python (Growing)</span>
            <span className="px-4 py-2 bg-secondary/80 hover:bg-secondary text-secondary-foreground rounded-xl text-sm font-medium transition-colors cursor-pointer border border-border/50">UI/UX Design</span>
          </div>
        </div>
        
        <div className="bg-card/40 backdrop-blur-xl border border-border/50 rounded-2xl p-7 shadow-lg shadow-black/5">
          <h3 className="font-bold text-xl mb-6">Suggestions</h3>
          <div className="space-y-4">
            <ConnectionItem name="Alice Smith" skills="Python, Data Science" />
            <ConnectionItem name="Bob Jones" skills="React, Node.js" />
          </div>
        </div>
      </div>
    </div>
  );
}

function NavItem({ icon, label, to, active = false }: { icon: React.ReactNode, label: string, to: string, active?: boolean }) {
  return (
    <Link to={to} className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-200 ${active ? 'bg-primary/15 text-primary font-semibold shadow-inner' : 'text-muted-foreground hover:bg-secondary/60 hover:text-foreground hover:translate-x-1'}`}>
      {React.cloneElement(icon as React.ReactElement<any>, { className: `w-5 h-5 ${active ? 'text-primary' : ''}` })}
      <span>{label}</span>
    </Link>
  );
}

function StatCard({ label, value, icon }: { label: string, value: string, icon: React.ReactNode }) {
  return (
    <div className="bg-card/40 backdrop-blur-xl border border-border/50 rounded-2xl p-6 shadow-lg shadow-black/5 hover:shadow-primary/5 transition-all hover:-translate-y-1 group">
      <div className="flex items-start justify-between mb-4">
        <p className="text-sm font-semibold text-muted-foreground group-hover:text-foreground transition-colors">{label}</p>
        <div className="p-2 bg-secondary/50 rounded-xl group-hover:bg-secondary transition-colors">
          {icon}
        </div>
      </div>
      <h3 className="text-4xl font-extrabold tracking-tight">{value}</h3>
    </div>
  );
}

function ConnectionItem({ name, skills }: { name: string, skills: string }) {
  return (
    <div className="flex items-center justify-between p-3 border border-border/40 rounded-xl hover:bg-secondary/60 transition-all cursor-pointer group hover:shadow-md">
      <div className="flex items-center space-x-4">
        <div className="w-11 h-11 rounded-full bg-gradient-to-br from-gray-700 to-gray-600 flex items-center justify-center shadow-inner group-hover:scale-105 transition-transform">
          <User className="w-5 h-5 text-gray-300" />
        </div>
        <div>
          <p className="font-semibold text-sm group-hover:text-primary transition-colors">{name}</p>
          <p className="text-xs text-muted-foreground mt-0.5">{skills}</p>
        </div>
      </div>
    </div>
  );
}
