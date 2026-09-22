import React from 'react';
import { Link } from 'react-router-dom';
import { 
  Users, 
  Wrench, 
  UserCheck, 
  WalletCards, 
  ArrowUpRight, 
  Clock, 
  MapPin, 
  CheckCircle2, 
  AlertTriangle,
  ChevronRight,
  TrendingUp,
  Activity
} from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

export default function DashboardPage() {
  const { tukangList, usersList, ticketsList, withdrawalsList } = useAdminData();

  const totalUsers = usersList.length;
  const verifiedTukang = tukangList.filter(t => t.verificationStatus === 'verified').length;
  const pendingKyc = tukangList.filter(t => t.verificationStatus === 'pending_verification');
  const suspendedTukang = tukangList.filter(t => t.isSuspended);
  const activeTickets = ticketsList.filter(t => t.status !== 'COMPLETED' && t.status !== 'CANCELED');
  const completedTickets = ticketsList.filter(t => t.status === 'COMPLETED');
  const totalVolumeRupiah = completedTickets.reduce((acc, curr) => acc + (curr.finalBill?.totalAmount || 0), 0);

  const stats = [
    {
      title: 'Total Pengguna Terdaftar',
      value: totalUsers,
      unit: 'orang',
      change: '+14% bln ini',
      trend: 'up',
      icon: Users,
      color: 'blue'
    },
    {
      title: 'Mitra Tukang Terverifikasi',
      value: verifiedTukang,
      unit: 'mitra aktif',
      change: `${pendingKyc.length} menunggu Verifikasi`,
      trend: pendingKyc.length > 0 ? 'warning' : 'neutral',
      icon: Wrench,
      color: 'emerald'
    },
    {
      title: 'Pekerjaan Berjalan',
      value: activeTickets.length,
      unit: 'tiket aktif',
      change: 'Realtime Live',
      trend: 'up',
      icon: Activity,
      color: 'amber'
    },
    {
      title: 'Total Transaksi Selesai',
      value: `Rp ${totalVolumeRupiah.toLocaleString('id-ID')}`,
      unit: '0% fee peluncuran',
      change: '100% diterima mitra',
      trend: 'neutral',
      icon: WalletCards,
      color: 'purple'
    }
  ];

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Ringkasan Operasional</h2>
          <p className="text-sm text-slate-500 mt-1">
            Pantau performa harian, verifikasi mitra tukang baru, dan pengawasan tiket langsung.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Link
            to="/kyc"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold shadow-md shadow-blue-600/20 transition-all"
          >
            <UserCheck className="w-4 h-4" />
            <span>Tinjau Mitra Baru ({pendingKyc.length})</span>
          </Link>

          <Link
            to="/live-map"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-slate-50 text-slate-700 border border-slate-300 text-sm font-semibold transition-all shadow-xs"
          >
            <MapPin className="w-4 h-4 text-emerald-600" />
            <span>Peta GPS Live</span>
          </Link>
        </div>
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {stats.map((s, idx) => {
          const Icon = s.icon;
          return (
            <div 
              key={idx} 
              className="bg-white rounded-2xl p-5 border border-slate-200/80 shadow-xs hover:shadow-md transition-shadow relative overflow-hidden group"
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-semibold text-slate-500 tracking-wide uppercase">{s.title}</span>
                <div className={`w-9 h-9 rounded-xl flex items-center justify-center ${
                  s.color === 'blue' ? 'bg-blue-50 text-blue-600' :
                  s.color === 'emerald' ? 'bg-emerald-50 text-emerald-600' :
                  s.color === 'amber' ? 'bg-amber-50 text-amber-600' :
                  'bg-purple-50 text-purple-600'
                }`}>
                  <Icon className="w-5 h-5" />
                </div>
              </div>

              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold text-slate-900 tracking-tight">{s.value}</span>
              </div>

              <div className="flex items-center justify-between mt-3 pt-3 border-t border-slate-100 text-xs text-slate-500">
                <span className="font-medium text-slate-400">{s.unit}</span>
                <span className={`font-semibold flex items-center gap-0.5 ${
                  s.trend === 'warning' ? 'text-amber-600' : 'text-slate-600'
                }`}>
                  {s.change}
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Actionable Alerts (KYC & Suspends) */}
      {(pendingKyc.length > 0 || suspendedTukang.length > 0) && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {/* Pending KYC Alert */}
          {pendingKyc.length > 0 && (
            <div className="bg-amber-50/70 border border-amber-200 rounded-2xl p-5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-xl bg-amber-500 text-white flex items-center justify-center shrink-0 shadow-sm shadow-amber-500/20">
                <UserCheck className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-slate-900 text-sm">Ada {pendingKyc.length} Calon Mitra Menunggu Verifikasi Pendaftaran</h3>
                  <span className="text-[10px] uppercase font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 border border-amber-300">
                    Prioritas
                  </span>
                </div>
                <p className="text-xs text-slate-600 mt-1">
                  Mitra tukang baru belum bisa mengambil atau menawar order sebelum keahlian dan nomor rekening payout diperiksa admin.
                </p>
                <div className="mt-3 flex items-center gap-3">
                  <Link
                    to="/kyc"
                    className="text-xs font-bold text-amber-900 hover:text-amber-950 inline-flex items-center gap-1 underline underline-offset-2"
                  >
                    Buka Antrean Verifikasi <ChevronRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </div>
            </div>
          )}

          {/* Suspended Alert */}
          {suspendedTukang.length > 0 && (
            <div className="bg-rose-50/70 border border-rose-200 rounded-2xl p-5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-xl bg-rose-600 text-white flex items-center justify-center shrink-0 shadow-sm shadow-rose-600/20">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-slate-900 text-sm">{suspendedTukang.length} Mitra Sedang Dalam Masa Sanksi (Suspend 3 Hari)</h3>
                </div>
                <p className="text-xs text-slate-600 mt-1">
                  Akses bidding dan job radar mitra ini telah dinonaktifkan sementara demi menjaga kepuasan pelanggan.
                </p>
                <div className="mt-3 flex items-center gap-3">
                  <Link
                    to="/tukang"
                    className="text-xs font-bold text-rose-900 hover:text-rose-950 inline-flex items-center gap-1 underline underline-offset-2"
                  >
                    Lihat Daftar Suspend <ChevronRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Two Column Section: Live Jobs & Quick Tukang Status */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left 2 Cols: Active Tickets Live Stream */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200/80 shadow-xs p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-bold text-slate-900 text-base">Aktivitas Tiket Terkini</h3>
              <p className="text-xs text-slate-500">Tiket pekerjaan yang sedang aktif dikerjakan oleh mitra</p>
            </div>
            <Link to="/tickets" className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1">
              Lihat Semua <ArrowUpRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="divide-y divide-slate-100">
            {ticketsList.map(ticket => (
              <div key={ticket.id} className="py-4 first:pt-2 last:pb-0 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-400">#{ticket.id}</span>
                    <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-slate-100 text-slate-700">
                      {ticket.categoryLabel}
                    </span>
                    <span className={`text-[11px] font-semibold px-2.5 py-0.5 rounded-full ${
                      ticket.status === 'COMPLETED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                      ticket.status === 'ON_THE_WAY' ? 'bg-blue-50 text-blue-700 border border-blue-200' :
                      'bg-amber-50 text-amber-700 border border-amber-200'
                    }`}>
                      {ticket.statusLabel}
                    </span>
                  </div>

                  <h4 className="text-sm font-semibold text-slate-900 line-clamp-1">{ticket.title}</h4>
                  
                  <div className="flex items-center gap-3 text-xs text-slate-500">
                    <span>Pelanggan: <strong className="text-slate-700">{ticket.userName}</strong></span>
                    <span>•</span>
                    <span>Tukang: <strong className="text-slate-700">{ticket.selectedTukangName || 'Menunggu Bidding'}</strong></span>
                  </div>
                </div>

                <div className="sm:text-right shrink-0">
                  <p className="text-sm font-bold text-slate-900">
                    {ticket.finalBill?.totalAmount 
                      ? `Rp ${ticket.finalBill.totalAmount.toLocaleString('id-ID')}` 
                      : (ticket.bids[0]?.estimatedPrice ? `Estimasi Rp ${ticket.bids[0].estimatedPrice.toLocaleString('id-ID')}` : 'Belum ada harga')}
                  </p>
                  <p className="text-[11px] text-slate-400 mt-0.5">{ticket.createdAt}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right 1 Col: Quick Tukang Status */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs p-6 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="font-bold text-slate-900 text-base">Status Mitra Terkini</h3>
                <p className="text-xs text-slate-500">Monitoring cepat ketersediaan tukang</p>
              </div>
              <Link to="/tukang" className="text-xs font-semibold text-blue-600 hover:text-blue-700">
                Kelola
              </Link>
            </div>

            <div className="space-y-3">
              {tukangList.slice(0, 4).map(t => (
                <div key={t.id} className="p-3 rounded-xl border border-slate-100 hover:bg-slate-50 transition-colors flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3 min-w-0">
                    <img 
                      src={t.avatar} 
                      alt={t.name} 
                      className="w-10 h-10 rounded-xl object-cover ring-1 ring-slate-200" 
                    />
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-slate-900 truncate">{t.name}</p>
                      <p className="text-xs text-slate-500 truncate capitalize">
                        {t.services.join(', ')}
                      </p>
                    </div>
                  </div>

                  <div className="text-right shrink-0">
                    {t.isSuspended ? (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-rose-50 text-rose-700 border border-rose-200">
                        Suspend
                      </span>
                    ) : t.verificationStatus === 'pending_verification' ? (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-200">
                        Pending KYC
                      </span>
                    ) : (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200">
                        Aktif
                      </span>
                    )}
                    <p className="text-[11px] text-slate-400 mt-1">⭐ {t.rating.toFixed(1)}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <Link
            to="/live-map"
            className="w-full py-3 px-4 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold text-center flex items-center justify-center gap-2 shadow-xs transition-colors"
          >
            <MapPin className="w-4 h-4 text-emerald-400" />
            <span>Buka Radar Peta Layar Penuh</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
