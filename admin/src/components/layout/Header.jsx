import React, { useState, useEffect } from 'react';
import { Clock, ShieldCheck, Bell, Sparkles } from 'lucide-react';
import { useAdminData } from '../../context/AdminDataContext';

export default function Header() {
  const { tukangList, ticketsList, toast, isLiveConnected } = useAdminData();
  const [time, setTime] = useState('');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTime(now.toLocaleTimeString('id-ID', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        timeZoneName: 'short'
      }));
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  const onlineTukangCount = tukangList.filter(t => t.isOnline && !t.isSuspended).length;
  const activeTicketsCount = ticketsList.filter(t => t.status !== 'COMPLETED' && t.status !== 'CANCELED').length;

  return (
    <header className="h-18 bg-white border-b border-slate-200/80 px-8 flex items-center justify-between sticky top-0 z-30 shadow-xs">
      {/* Toast Notification Float */}
      {toast && (
        <div className={`fixed top-4 right-8 z-50 flex items-center gap-3 px-4 py-3 rounded-xl shadow-xl border text-sm font-medium transition-all animate-in fade-in slide-in-from-top-2 duration-200 ${
          toast.type === 'error' 
            ? 'bg-rose-50 border-rose-200 text-rose-800' 
            : 'bg-emerald-50 border-emerald-200 text-emerald-800'
        }`}>
          <span className={`w-2 h-2 rounded-full ${toast.type === 'error' ? 'bg-rose-500' : 'bg-emerald-500'}`} />
          <span>{toast.message}</span>
        </div>
      )}

      {/* Left Title & Status Badges */}
      <div className="flex items-center gap-4">
        <div>
          <h1 className="text-base font-bold text-slate-900 tracking-tight">Pusat Kendali Operasional</h1>
          <p className="text-xs text-slate-500">Ekosistem Jasa Tukang Beres</p>
        </div>

        <div className="hidden md:flex items-center gap-2 pl-4 border-l border-slate-200">
          <div 
            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${
              isLiveConnected 
                ? 'bg-emerald-50 text-emerald-700 border-emerald-200/60' 
                : 'bg-slate-50 text-slate-600 border-slate-200'
            }`}
            title={isLiveConnected ? "Terhubung ke Cloud Firestore beress-app" : "Mode Standalone"}
          >
            <span className={`w-2 h-2 rounded-full ${isLiveConnected ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'}`} />
            <span>{isLiveConnected ? 'Cloud Firestore Live' : 'Demo Mode'}</span>
          </div>

          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-50 text-slate-700 border border-slate-200 text-xs font-semibold">
            <span>{onlineTukangCount} Mitra Online</span>
          </div>

          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200/60 text-xs font-semibold">
            <span>{activeTicketsCount} Tiket Aktif</span>
          </div>
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 text-xs font-medium text-slate-600 bg-slate-100 px-3 py-1.5 rounded-lg border border-slate-200">
          <Clock className="w-3.5 h-3.5 text-slate-500" />
          <span>{time || '08:00 WIB'}</span>
        </div>

        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-900 text-white text-xs font-semibold shadow-xs">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
          <span>Admin Terverifikasi</span>
        </div>
      </div>
    </header>
  );
}
