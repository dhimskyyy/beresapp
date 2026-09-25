import React, { useEffect, useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { signInWithEmailAndPassword, signOut, onAuthStateChanged } from 'firebase/auth';
import { AdminDataProvider } from './context/AdminDataContext';
import { auth } from './firebase';
import AdminLayout from './components/layout/AdminLayout';
import DashboardPage from './pages/DashboardPage';
import KycApprovalPage from './pages/KycApprovalPage';
import TukangMapPage from './pages/TukangMapPage';
import TukangListPage from './pages/TukangListPage';
import UserListPage from './pages/UserListPage';
import TicketMonitorPage from './pages/TicketMonitorPage';

function AdminLogin({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async (event) => {
    event.preventDefault();
    setError('');
    setLoading(true);
    try {
      const credential = await signInWithEmailAndPassword(auth, email.trim(), password);
      const token = await credential.user.getIdTokenResult(true);
      if (token.claims.admin !== true) {
        await signOut(auth);
        throw new Error('Akun ini tidak memiliki akses admin.');
      }
      onLogin(credential.user);
    } catch (loginError) {
      setError(loginError.message || 'Login admin gagal.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-slate-950 flex items-center justify-center p-6">
      <form onSubmit={submit} className="w-full max-w-sm bg-white rounded-2xl p-6 space-y-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Admin Beres</h1>
          <p className="text-sm text-slate-500 mt-1">Masuk dengan akun admin terverifikasi.</p>
        </div>
        <input required type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Email admin" className="w-full px-3 py-2 border rounded-lg" />
        <input required type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Password" className="w-full px-3 py-2 border rounded-lg" />
        {error && <p className="text-sm text-rose-600">{error}</p>}
        <button disabled={loading} className="w-full py-2 rounded-lg bg-blue-600 text-white font-semibold disabled:opacity-50">
          {loading ? 'Memeriksa...' : 'Masuk'}
        </button>
      </form>
    </main>
  );
}

function AdminShell() {
  return (
    <AdminDataProvider>
      <BrowserRouter>
        <div className="relative">
          <button onClick={() => signOut(auth)} className="fixed top-5 right-8 z-40 text-xs text-slate-500 hover:text-slate-900">Keluar</button>
          <Routes>
            <Route path="/" element={<AdminLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="kyc" element={<KycApprovalPage />} />
              <Route path="live-map" element={<TukangMapPage />} />
              <Route path="tukang" element={<TukangListPage />} />
              <Route path="users" element={<UserListPage />} />
              <Route path="tickets" element={<TicketMonitorPage />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Route>
          </Routes>
        </div>
      </BrowserRouter>
    </AdminDataProvider>
  );
}

export default function App() {
  const [user, setUser] = useState(undefined);

  useEffect(() => onAuthStateChanged(auth, async (nextUser) => {
    if (!nextUser) {
      setUser(null);
      return;
    }
    const token = await nextUser.getIdTokenResult(true);
    setUser(token.claims.admin === true ? nextUser : null);
    if (token.claims.admin !== true) await signOut(auth);
  }), []);

  if (user === undefined) return <div className="min-h-screen flex items-center justify-center">Memuat...</div>;
  if (!user) return <AdminLogin onLogin={setUser} />;

  return <AdminShell />;
}
