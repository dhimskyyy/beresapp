import React from 'react';
import { NavLink } from 'react-router-dom';
import { 
  LayoutDashboard, 
  UserCheck, 
  MapPin, 
  Wrench, 
  Users, 
  ClipboardList, 
  WalletCards, 
  ShieldAlert,
  RotateCcw
} from 'lucide-react';
import { useAdminData } from '../../context/AdminDataContext';

export default function Sidebar() {
  const { tukangList, withdrawalsList, resetDemoData } = useAdminData();

  const pendingKycCount = tukangList.filter(t => t.verificationStatus === 'pending_verification').length;
  const suspendedCount = tukangList.filter(t => t.isSuspended).length;
  const pendingWithdrawalCount = withdrawalsList.filter(w => w.status === 'pending').length;

  const navItems = [
    { to: '/', label: 'Ringkasan', icon: LayoutDashboard },
    { 
      to: '/kyc', 
      label: 'Verifikasi Mitra', 
      icon: UserCheck, 
      badge: pendingKycCount > 0 ? pendingKycCount : null,
      badgeColor: 'bg-amber-500 text-white'
    },
    { to: '/live-map', label: 'Lacak GPS Tukang', icon: MapPin, pulse: true },
    { 
      to: '/tukang', 
      label: 'Manajemen Tukang', 
      icon: Wrench,
      badge: suspendedCount > 0 ? `${suspendedCount} Suspend` : null,
      badgeColor: 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
    },
    { to: '/users', label: 'Daftar Pengguna', icon: Users },
    { to: '/tickets', label: 'Pantau Pekerjaan', icon: ClipboardList },
    { 
      to: '/withdrawals', 
      label: 'Pencairan Dana', 
      icon: WalletCards,
      badge: pendingWithdrawalCount > 0 ? pendingWithdrawalCount : null,
      badgeColor: 'bg-emerald-500 text-white'
    },
  ];

  return (
    <aside className="w-64 bg-slate-950 text-slate-300 flex flex-col shrink-0 border-r border-slate-800/80 select-none min-h-screen">
      {/* Brand Header */}
      <div className="h-18 flex items-center px-6 gap-3 border-b border-slate-800/60 bg-slate-950/40">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-700 to-blue-500 flex items-center justify-center text-white font-black text-xl shadow-lg shadow-blue-500/20 ring-1 ring-white/20">
          B
        </div>
        <div>
          <div className="flex items-center gap-2">
            <span className="font-bold text-white tracking-tight text-lg">Beres</span>
            <span className="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20">
              Admin
            </span>
          </div>
          <p className="text-[11px] text-slate-400 font-medium">Operations Dashboard</p>
        </div>
      </div>

      {/* Navigation Links */}
      <div className="flex-1 py-6 px-3 space-y-1.5 overflow-y-auto">
        <div className="px-3 pb-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">
          Menu Operasional
        </div>

        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) => `
                flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium transition-all duration-150 group
                ${isActive 
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-600/20 font-semibold' 
                  : 'text-slate-300 hover:bg-slate-900 hover:text-white'}
              `}
            >
              {({ isActive }) => (
                <>
                  <div className="flex items-center gap-3">
                    <Icon className={`w-4.5 h-4.5 transition-colors ${isActive ? 'text-white' : 'text-slate-400 group-hover:text-blue-400'}`} />
                    <span>{item.label}</span>
                  </div>

                  <div className="flex items-center gap-1.5">
                    {item.pulse && (
                      <span className="relative flex h-2 w-2">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                      </span>
                    )}
                    {item.badge && (
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${item.badgeColor}`}>
                        {item.badge}
                      </span>
                    )}
                  </div>
                </>
              )}
            </NavLink>
          );
        })}
      </div>

      {/* Footer Utility */}
      <div className="p-3 border-t border-slate-800/80 bg-slate-950/60 space-y-2">
        <button
          onClick={resetDemoData}
          className="w-full flex items-center justify-center gap-2 py-2 px-3 text-xs font-medium text-slate-300 hover:text-white bg-slate-900 hover:bg-slate-800 rounded-lg border border-slate-800 transition-colors"
          title="Kembalikan semua data ke simulasi awal"
        >
          <RotateCcw className="w-3.5 h-3.5 text-slate-400" />
          <span>Reset Data Demo</span>
        </button>

        <div className="flex items-center gap-3 p-2 rounded-lg bg-slate-900/40 border border-slate-800/60">
          <div className="w-8 h-8 rounded-full bg-blue-900/60 border border-blue-700/50 flex items-center justify-center text-blue-300 font-bold text-xs">
            SA
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-white truncate">Super Admin</p>
            <p className="text-[10px] text-emerald-400 flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block"></span>
              Live Connected
            </p>
          </div>
        </div>
      </div>
    </aside>
  );
}
