import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyBlY15vkdbQUtkeOl9m-Ox4gl0Be-4twJ0",
  authDomain: "smart-student-platform-fe510.firebaseapp.com",
  projectId: "smart-student-platform-fe510",
  storageBucket: "smart-student-platform-fe510.firebasestorage.app",
  messagingSenderId: "323647940211",
  appId: "1:323647940211:web:cbeb7317ff1efc30e6ec06",
  measurementId: "G-PKN61V3HX0"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
