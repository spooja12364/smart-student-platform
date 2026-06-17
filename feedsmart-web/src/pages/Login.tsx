import { Link } from 'react-router-dom';
import { Users, Mail, Lock } from 'lucide-react';

export default function Login() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4 relative overflow-hidden">
      {/* Dynamic Backgrounds */}
      <div className="absolute top-10 right-10 w-96 h-96 bg-primary/10 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob"></div>
      
      <div className="w-full max-w-md bg-card/60 backdrop-blur-xl border border-border p-8 md:p-10 rounded-[2rem] shadow-2xl relative z-10 animate-in fade-in zoom-in duration-700">
        
        <div className="text-center mb-10">
          <div className="flex justify-center mb-6">
            <div className="h-14 w-14 bg-primary/20 border border-primary/30 rounded-2xl flex items-center justify-center transform rotate-6">
              <Users className="text-primary w-8 h-8 -rotate-6" />
            </div>
          </div>
          <h2 className="text-3xl font-extrabold tracking-tight">Welcome back</h2>
          <p className="text-muted-foreground mt-2">Login to your FeedSmart account</p>
        </div>
        
        <form className="space-y-6">
          <div className="space-y-2 relative group">
            <label className="text-sm font-medium ml-1">Username or Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground group-focus-within:text-primary transition-colors" />
              <input 
                type="text" 
                className="flex h-12 w-full rounded-xl border border-input bg-background/50 pl-12 pr-4 py-2 text-base focus:ring-2 focus:ring-primary transition-all" 
                placeholder="Enter your username" 
              />
            </div>
          </div>
          
          <div className="space-y-2 relative group">
            <label className="text-sm font-medium ml-1">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground group-focus-within:text-primary transition-colors" />
              <input 
                type="password" 
                className="flex h-12 w-full rounded-xl border border-input bg-background/50 pl-12 pr-4 py-2 text-base focus:ring-2 focus:ring-primary transition-all" 
                placeholder="••••••••" 
              />
            </div>
          </div>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <input type="checkbox" id="remember" className="rounded border-border bg-background w-4 h-4 text-primary focus:ring-primary" />
              <label htmlFor="remember" className="text-sm cursor-pointer select-none">Remember me</label>
            </div>
            <a href="#" className="text-sm text-primary font-medium hover:underline">Forgot password?</a>
          </div>

          <Link to="/dashboard" className="w-full flex items-center justify-center rounded-xl bg-primary text-primary-foreground font-semibold hover:bg-primary/90 h-12 px-4 shadow-[0_0_20px_-5px_rgba(59,130,246,0.5)] hover:shadow-[0_0_30px_-5px_rgba(59,130,246,0.7)] transition-all hover:-translate-y-0.5">
            Login
          </Link>
        </form>



        <p className="text-center text-sm text-muted-foreground mt-8">
          New User? <Link to="/register" className="text-primary font-medium hover:underline">Create Your Profile</Link>
        </p>
      </div>
    </div>
  );
}
