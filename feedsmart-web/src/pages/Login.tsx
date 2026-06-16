import React from 'react';
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

        <div className="relative my-8">
          <div className="absolute inset-0 flex items-center">
            <span className="w-full border-t border-border" />
          </div>
          <div className="relative flex justify-center text-xs uppercase">
            <span className="bg-card px-4 text-muted-foreground font-medium">Or continue with</span>
          </div>
        </div>

        <button type="button" className="w-full inline-flex items-center justify-center rounded-xl border border-border bg-background/50 hover:bg-background h-12 px-4 font-medium transition-colors shadow-sm">
          <svg className="w-5 h-5 mr-3" viewBox="0 0 24 24">
            <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
          </svg>
          Google
        </button>

        <p className="text-center text-sm text-muted-foreground mt-8">
          New User? <Link to="/register" className="text-primary font-medium hover:underline">Create Your Profile</Link>
        </p>
      </div>
    </div>
  );
}
