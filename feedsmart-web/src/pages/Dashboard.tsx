import React from 'react';
import { Routes, Route, Link } from 'react-router-dom';
import { LayoutDashboard, Users, MessageSquare, Bell, User, Settings, LogOut, Code } from 'lucide-react';

export default function Dashboard() {
  return (
    <div className="min-h-screen bg-background flex">
      {/* Sidebar */}
      <aside className="w-64 border-r border-border bg-card hidden md:flex flex-col">
        <div className="p-6 flex items-center space-x-3 border-b border-border">
          <div className="h-8 w-8 bg-primary rounded-lg flex items-center justify-center transform rotate-3">
            <Users className="text-primary-foreground w-5 h-5 -rotate-3" />
          </div>
          <span className="font-bold text-xl tracking-tight">FeedSmart</span>
        </div>
        
        <nav className="flex-1 p-4 space-y-1">
          <NavItem icon={<LayoutDashboard />} label="Home" active />
          <NavItem icon={<Code />} label="Skills" />
          <NavItem icon={<Users />} label="Connections" />
          <NavItem icon={<MessageSquare />} label="Chats" />
          <NavItem icon={<Users />} label="Groups" />
          <NavItem icon={<Bell />} label="Notifications" />
          <NavItem icon={<User />} label="Profile" />
          <NavItem icon={<Settings />} label="Settings" />
        </nav>
        
        <div className="p-4 border-t border-border">
          <button className="flex items-center space-x-3 text-muted-foreground hover:text-foreground w-full p-2 rounded-md transition-colors">
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        <header className="h-16 border-b border-border bg-card flex items-center justify-between px-6">
          <h2 className="font-semibold text-lg">Dashboard</h2>
          <div className="flex items-center space-x-4">
            <button className="relative p-2 rounded-full hover:bg-secondary">
              <Bell className="w-5 h-5 text-muted-foreground" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
            <div className="h-8 w-8 rounded-full bg-primary/20 border border-primary/30 flex items-center justify-center overflow-hidden">
              <span className="text-xs font-bold text-primary">JD</span>
            </div>
          </div>
        </header>
        
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <StatCard label="Skills Count" value="5" />
            <StatCard label="Connections" value="124" />
            <StatCard label="Groups Joined" value="3" />
            <StatCard label="Profile Score" value="92%" />
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 bg-card border border-border rounded-xl p-6">
              <h3 className="font-semibold text-lg mb-4">Trending Skills</h3>
              <div className="flex flex-wrap gap-2">
                <span className="px-3 py-1 bg-secondary text-secondary-foreground rounded-full text-sm">React (High Demand)</span>
                <span className="px-3 py-1 bg-secondary text-secondary-foreground rounded-full text-sm">Python (Growing)</span>
                <span className="px-3 py-1 bg-secondary text-secondary-foreground rounded-full text-sm">UI/UX Design</span>
              </div>
            </div>
            
            <div className="bg-card border border-border rounded-xl p-6">
              <h3 className="font-semibold text-lg mb-4">Recommended Connections</h3>
              <div className="space-y-4">
                <ConnectionItem name="Alice Smith" skills="Python, Data Science" />
                <ConnectionItem name="Bob Jones" skills="React, Node.js" />
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

function NavItem({ icon, label, active = false }: { icon: React.ReactNode, label: string, active?: boolean }) {
  return (
    <a href="#" className={`flex items-center space-x-3 px-3 py-2 rounded-md transition-colors ${active ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:bg-secondary hover:text-foreground'}`}>
      {React.cloneElement(icon as React.ReactElement, { className: 'w-5 h-5' })}
      <span>{label}</span>
    </a>
  );
}

function StatCard({ label, value }: { label: string, value: string }) {
  return (
    <div className="bg-card border border-border rounded-xl p-6 shadow-sm">
      <p className="text-sm font-medium text-muted-foreground mb-1">{label}</p>
      <h3 className="text-3xl font-bold">{value}</h3>
    </div>
  );
}

function ConnectionItem({ name, skills }: { name: string, skills: string }) {
  return (
    <div className="flex items-center justify-between p-3 border border-border rounded-lg hover:bg-secondary/50 transition-colors cursor-pointer">
      <div className="flex items-center space-x-3">
        <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center">
          <User className="w-5 h-5 text-muted-foreground" />
        </div>
        <div>
          <p className="font-medium text-sm">{name}</p>
          <p className="text-xs text-muted-foreground">{skills}</p>
        </div>
      </div>
      <button className="text-xs bg-primary text-primary-foreground px-2 py-1 rounded-md hover:bg-primary/90">Connect</button>
    </div>
  );
}
