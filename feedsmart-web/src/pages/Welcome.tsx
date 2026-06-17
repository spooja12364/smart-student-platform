import React from 'react';
import { useNavigate } from 'react-router-dom';
import './Welcome.css'; // We will create this

const Welcome: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="welcome-container">
      <div className="welcome-glass-panel">
        <h1 className="welcome-title">Feed Smart Student Collaboration</h1>
        <p className="welcome-subtitle">
          Connect, grow, and build a powerful community with students just like you.
        </p>

        <div className="welcome-actions">
          <button className="btn btn-primary" onClick={() => navigate('/register')}>
            Get Started
          </button>
          
          <button className="btn btn-secondary" onClick={() => navigate('/login')}>
            Login
          </button>
          
        </div>
      </div>
    </div>
  );
};

export default Welcome;
