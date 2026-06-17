import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import emailjs from '@emailjs/browser';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../firebase';
import './Register.css';

// Types for our form data
interface RegistrationData {
  name: string;
  username: string;
  email: string;
  skills: Array<{ name: string; biodata: string }>;
  password: string;
  bio: string;
}

const Register: React.FC = () => {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState<RegistrationData>({
    name: '',
    username: '',
    email: '',
    skills: [],
    password: '',
    bio: ''
  });

  // Step 1 State
  const [usernameError, setUsernameError] = useState('');
  const [emailError, setEmailError] = useState('');

  // Step 2 State
  const [otp, setOtp] = useState('');
  const [timeLeft, setTimeLeft] = useState(300); // 5 minutes in seconds
  const [, setOtpSent] = useState(false);
  const [generatedOtp, setGeneratedOtp] = useState('');

  // Step 3 State
  const [currentSkill, setCurrentSkill] = useState({ name: '', biodata: '' });

  // Step 4 State
  const [captchaPassed, setCaptchaPassed] = useState(false);

  // --- Step 1 Handlers ---
  const handleBasicInfoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));

    // Mock Real-time validation
    if (name === 'username') {
      if (value.toLowerCase() === 'admin') setUsernameError('Username is already existing.');
      else setUsernameError('');
    }
    if (name === 'email') {
      if (value.toLowerCase() === 'test@test.com') setEmailError('Email is already registered.');
      else setEmailError('');
    }
  };

  const handleNextStep1 = () => {
    if (formData.name && formData.username && formData.email && !usernameError && !emailError) {
      setStep(2);
      startOtpTimer();
    }
  };

  // --- Step 2 Handlers (OTP) ---
  const startOtpTimer = async () => {
    const newOtp = Math.floor(1000 + Math.random() * 9000).toString();
    setGeneratedOtp(newOtp);
    setOtpSent(true);
    setTimeLeft(300);

    try {
      await emailjs.send(
        'service_hrowx0v',
        'template_kldht6j',
        {
          to_email: formData.email,
          user_email: formData.email,
          email: formData.email,
          recipient: formData.email,
          otp: newOtp,
          message: newOtp,
          code: newOtp,
          OTP: newOtp,
          verification_code: newOtp
        },
        '0SSH8Hp7Vq8L7F_p-'
      );
      console.log('OTP sent successfully');
    } catch (err) {
      console.error('Failed to send OTP', err);
      alert('Failed to send OTP. Please check the console.');
    }
  };

  useEffect(() => {
    let timer: ReturnType<typeof setInterval>;
    if (step === 2 && timeLeft > 0) {
      timer = setInterval(() => setTimeLeft(prev => prev - 1), 1000);
    }
    return () => clearInterval(timer);
  }, [step, timeLeft]);

  const handleResendOtp = () => {
    startOtpTimer();
  };

  const handleVerifyOtp = () => {
    if (otp === generatedOtp || otp === '1234') { // Mock OTP check
      setStep(3);
    } else {
      alert('Invalid OTP. Please try again.');
    }
  };

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  // --- Step 3 Handlers (Skills) ---
  const handleAddSkill = () => {
    if (currentSkill.name && currentSkill.biodata && formData.skills.length < 4) {
      setFormData(prev => ({
        ...prev,
        skills: [...prev.skills, currentSkill]
      }));
      setCurrentSkill({ name: '', biodata: '' });
    }
  };

  const handleNextStep3 = () => {
    if (formData.skills.length > 0) setStep(4);
    else alert('Please add at least one skill.');
  };

  // --- Step 4 Handlers (Security & Bio) ---
  const handleRegister = async () => {
    if (!captchaPassed) {
      alert('Please complete the Captcha.');
      return;
    }
    if (!formData.password || !formData.bio) {
      alert('Please complete all fields.');
      return;
    }

    try {
      // 1. Create user in Firebase Auth
      const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
      const user = userCredential.user;

      // 2. Save profile and skills to Firestore 'users' collection
      await setDoc(doc(db, 'users', user.uid), {
        name: formData.name,
        username: formData.username,
        email: formData.email,
        bio: formData.bio,
        skills: formData.skills,
        createdAt: serverTimestamp(),
      });

      alert('Registration Successful! Redirecting to dashboard...');
      navigate('/dashboard');
    } catch (error: any) {
      console.error('Registration failed:', error);
      alert(`Registration Failed: ${error.message}`);
    }
  };

  return (
    <div className="app-container flex-center">
      <div className="glass-panel register-panel">
        <h2 className="step-title">Step {step} of 4</h2>
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${(step / 4) * 100}%` }}></div>
        </div>

        {/* STEP 1: Basic Info */}
        {step === 1 && (
          <div className="step-content animation-fade-in">
            <h3>Partner's Profile</h3>
            <div className="input-group">
              <label className="input-label">Full Name</label>
              <input className="input-field" name="name" value={formData.name} onChange={handleBasicInfoChange} placeholder="e.g. John Doe" />
            </div>
            
            <div className="input-group">
              <label className="input-label">Username</label>
              <input className="input-field" name="username" value={formData.username} onChange={handleBasicInfoChange} placeholder="Choose a unique username" />
              {usernameError && <span className="error-text">{usernameError}</span>}
            </div>

            <div className="input-group">
              <label className="input-label">Email ID</label>
              <input className="input-field" type="email" name="email" value={formData.email} onChange={handleBasicInfoChange} placeholder="your.email@example.com" />
              {emailError && <span className="error-text">{emailError}</span>}
            </div>

            <button className="btn btn-primary full-width mt-4" onClick={handleNextStep1} disabled={!formData.name || !formData.username || !formData.email || !!usernameError || !!emailError}>
              Next
            </button>
          </div>
        )}

        {/* STEP 2: OTP Verification */}
        {step === 2 && (
          <div className="step-content animation-fade-in">
            <h3>OTP Verification</h3>
            <p className="subtitle">We've sent a code to {formData.email}</p>
            
            <div className="input-group mt-4">
              <label className="input-label">Enter OTP</label>
              <input className="input-field otp-input" type="text" maxLength={4} value={otp} onChange={e => setOtp(e.target.value)} placeholder="• • • •" />
            </div>

            <div className="otp-actions">
              <span className={timeLeft === 0 ? "error-text" : "timer-text"}>
                {timeLeft > 0 ? `Time remaining: ${formatTime(timeLeft)}` : 'OTP Expired'}
              </span>
              <button className="btn btn-secondary small-btn" onClick={handleResendOtp}>Resend OTP</button>
            </div>

            <div className="btn-group mt-4">
              <button className="btn btn-secondary" onClick={() => setStep(1)}>Back</button>
              <button className="btn btn-primary" onClick={handleVerifyOtp} disabled={otp.length < 4 || timeLeft === 0}>Verify</button>
            </div>
          </div>
        )}

        {/* STEP 3: Skills */}
        {step === 3 && (
          <div className="step-content animation-fade-in">
            <h3>Skill Exchange</h3>
            <p className="subtitle">Add 1 to 4 skills you can share or want to learn.</p>
            
            <div className="skills-list mb-4">
              {formData.skills.map((skill, index) => (
                <div key={index} className="skill-chip">
                  <strong>{skill.name}</strong> - {skill.biodata}
                </div>
              ))}
            </div>

            {formData.skills.length < 4 && (
              <div className="add-skill-box">
                <input className="input-field mb-2" placeholder="Skill Name (e.g. React.js)" value={currentSkill.name} onChange={e => setCurrentSkill({...currentSkill, name: e.target.value})} />
                <textarea className="input-field mb-2" rows={2} placeholder="Short biodata about this skill..." value={currentSkill.biodata} onChange={e => setCurrentSkill({...currentSkill, biodata: e.target.value})} />
                <button className="btn btn-secondary full-width" onClick={handleAddSkill}>+ Add Skill</button>
              </div>
            )}

            <div className="btn-group mt-4">
              <button className="btn btn-secondary" onClick={() => setStep(2)}>Back</button>
              <button className="btn btn-primary" onClick={handleNextStep3} disabled={formData.skills.length === 0}>Next</button>
            </div>
          </div>
        )}

        {/* STEP 4: Security & Bio */}
        {step === 4 && (
          <div className="step-content animation-fade-in">
            <h3>Finalizing Profile</h3>
            
            <div className="input-group">
              <label className="input-label">Short Bio</label>
              <textarea className="input-field" rows={3} value={formData.bio} onChange={e => setFormData({...formData, bio: e.target.value})} placeholder="Tell the community about yourself..." />
            </div>

            <div className="input-group">
              <label className="input-label">Password</label>
              <input className="input-field" type="password" value={formData.password} onChange={e => setFormData({...formData, password: e.target.value})} placeholder="Create a strong password" />
            </div>

            <div className="captcha-box mb-4">
              <label className="input-label">Human Verification</label>
              <div className={`custom-captcha ${captchaPassed ? 'passed' : ''}`} onClick={() => setCaptchaPassed(!captchaPassed)}>
                {captchaPassed ? '✅ Verified Human' : '🧠 Click to verify you are human (Unique Captcha)'}
              </div>
            </div>

            <div className="btn-group mt-4">
              <button className="btn btn-secondary" onClick={() => setStep(3)}>Back</button>
              <button className="btn btn-primary" onClick={handleRegister} disabled={!formData.password || !formData.bio || !captchaPassed}>Register</button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};

export default Register;
