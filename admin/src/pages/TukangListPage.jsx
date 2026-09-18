import React, { useState } from 'react';
import { 
  Wrench, 
  Search, 
  AlertTriangle, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  ShieldAlert, 
  Star, 
  MoreVertical,
  RotateCcw,
  SlidersHorizontal,
  Wallet
} from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

export default function TukangListPage() {
  const { tukangList, suspendTukang, unsuspendTukang } = useAdminData();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedService, setSelectedService] = useState('ALL');
  const [suspendModalTukang, setSuspendModalTukang] = useState(null);
  const [suspendReason, setSuspendReason] = useState('');
  const [customReason, setCustomReason] = useState('');

  const violationPresets = [
    'Membatalkan order sepihak setelah update Menuju Lokasi',
    'Meminta pungutan liar / tarif di luar invoice aplikasi',
    'Perilaku tidak sopan / tidak profesional pada pelanggan',
    'Terlambat lebih dari 1 jam tanpa konfirmasi kabar',
    'Hasil pengerjaan buruk dan tidak bertanggung jawab',
    'Lainnya (Tulis Manual)'
  ];

  const filteredTukang = tukangList.filter(t => {
    const matchesSearch = 
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.phone.includes(searchQuery) ||
      t.email.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesService = selectedService === 'ALL' || t.services.includes(selectedService);

    return matchesSearch && matchesService;
  });

  const handleApplySuspend = () => {
    const finalReason = suspendReason === 'Lainnya (Tulis Manual)' ? customReason : suspendReason;
    if (!finalReason) {
      alert('Mohon pilih atau tuliskan alasan pelanggaran.');
      return;
    }

    suspendTukang(suspendModalTukang.id, finalReason, 3);
    setSuspendModalTukang(null);
    setSuspendReason('');
    setCustomReason('');
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Manajemen Mitra Tukang</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-700">
              Total {tukangList.length} Mitra
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Kelola data mitra tukang, pantau rating, saldo dompet, serta penegakan disiplin dan sanksi suspend.
          </p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari nama tukang, nomor HP, atau email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
          />
        </div>

        {/* Category Service Dropdown Filter */}
        <div className="flex items-center gap-2">
          <SlidersHorizontal className="w-4 h-4 text-slate-400" />
          <select
            value={selectedService}
            onChange={(e) => setSelectedService(e.target.value)}
            className="text-xs font-semibold bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            <option value="ALL">Semua Kategori Keahlian</option>
            <option value="ac">AC</option>
            <option value="cleaning">Cleaning</option>
            <option value="elektronik">Elektronik</option>
            <option value="las">Las</option>
            <option value="bangunan">Bangunan</option>
            <option value="besi_baja">Besi & Baja</option>
            <option value="bengkel_motor">Bengkel Motor</option>
            <option value="bengkel_mobil">Bengkel Mobil</option>
            <option value="pengrajin_kayu">Pengrajin Kayu</option>
            <option value="plumbing">Plumbing</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 uppercase tracking-wider text-[11px]">
              <tr>
                <th className="py-3.5 px-5">Profil Mitra</th>
                <th className="py-3.5 px-4">Keahlian</th>
                <th className="py-3.5 px-4">Rating & Order</th>
                <th className="py-3.5 px-4">Saldo Dompet</th>
                <th className="py-3.5 px-4">Status Akun</th>
                <th className="py-3.5 px-5 text-right">Disiplin & Sanksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredTukang.map((t) => (
                <tr key={t.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="py-4 px-5">
                    <div className="flex items-center gap-3">
                      <img 
                        src={t.avatar} 
                        alt={t.name} 
                        className="w-10 h-10 rounded-xl object-cover ring-1 ring-slate-200" 
                      />
                      <div>
                        <div className="flex items-center gap-1.5">
                          <p className="font-bold text-slate-900">{t.name}</p>
                          {t.verificationStatus === 'verified' && (
                            <CheckCircle2 className="w-3.5 h-3.5 text-blue-600 inline" title="Mitra Terverifikasi" />
                          )}
                        </div>
                        <p className="text-slate-400 text-[11px]">{t.phone}</p>
                        <p className="text-slate-500 text-[10px] font-mono">{t.id}</p>
                      </div>
                    </div>
                  </td>

                  <td className="py-4 px-4">
                    <div className="flex flex-wrap gap-1 max-w-xs">
                      {t.services.map(s => (
                        <span key={s} className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 font-semibold text-[10px] uppercase">
                          {s}
                        </span>
                      ))}
                    </div>
                  </td>

                  <td className="py-4 px-4">
                    <div className="flex items-center gap-1 font-bold text-slate-900">
                      <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                      <span>{t.rating.toFixed(1)}</span>
                      <span className="text-slate-400 font-normal">({t.reviewCount} ulasan)</span>
                    </div>
                    <p className="text-[11px] text-slate-500 mt-0.5">{t.totalJobsDone} pekerjaan tuntas</p>
                  </td>

                  <td className="py-4 px-4">
                    <p className="font-bold text-slate-900 font-mono">
                      Rp {t.walletBalance.toLocaleString('id-ID')}
                    </p>
                    <p className="text-[10px] text-slate-400">Siap ditarik</p>
                  </td>

                  <td className="py-4 px-4">
                    {t.isSuspended ? (
                      <div className="space-y-1">
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-50 text-rose-700 border border-rose-200 text-[11px] font-bold">
                          <AlertTriangle className="w-3 h-3 text-rose-600" />
                          Suspended (3 Hari)
                        </span>
                        <p className="text-[10px] text-rose-600 max-w-[180px] truncate" title={t.suspendReason}>
                          Alasan: {t.suspendReason}
                        </p>
                      </div>
                    ) : t.verificationStatus === 'pending_verification' ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 text-[11px] font-semibold">
                        Menunggu KTP
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                        Aktif
                      </span>
                    )}
                  </td>

                  <td className="py-4 px-5 text-right">
                    {t.isSuspended ? (
                      <button
                        onClick={() => unsuspendTukang(t.id)}
                        className="px-3 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-300 font-bold text-xs transition-colors flex items-center gap-1.5 ml-auto"
                      >
                        <RotateCcw className="w-3.5 h-3.5" />
                        <span>Cabut Suspend</span>
                      </button>
                    ) : (
                      <button
                        onClick={() => {
                          setSuspendModalTukang(t);
                          setSuspendReason(violationPresets[0]);
                        }}
                        className="px-3.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 font-bold text-xs transition-colors flex items-center gap-1.5 ml-auto"
                      >
                        <ShieldAlert className="w-3.5 h-3.5" />
                        <span>Suspend 3 Hari</span>
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Suspend 3 Hari */}
      {suspendModalTukang && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200 overflow-hidden">
            {/* Modal Header */}
            <div className="p-6 bg-rose-50 border-b border-rose-100 flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-rose-600 text-white flex items-center justify-center shrink-0 shadow-md shadow-rose-600/20">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-rose-950">Jatuhkan Sanksi Suspend 3 Hari</h3>
                <p className="text-xs text-rose-700">Mitra tidak dapat mengambil order baru selama 72 jam</p>
              </div>
            </div>

            {/* Modal Body */}
            <div className="p-6 space-y-4">
              {/* Target Tukang Info */}
              <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-200/80">
                <img src={suspendModalTukang.avatar} alt="" className="w-10 h-10 rounded-xl object-cover" />
                <div>
                  <p className="font-bold text-slate-900 text-xs">{suspendModalTukang.name}</p>
                  <p className="text-[11px] text-slate-500">ID: {suspendModalTukang.id} • {suspendModalTukang.phone}</p>
                </div>
              </div>

              {/* Pilih Alasan Pelanggaran */}
              <div className="space-y-2">
                <label className="block text-xs font-bold text-slate-700">
                  Pilih Kategori Pelanggaran:
                </label>
                <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                  {violationPresets.map((preset) => (
                    <label 
                      key={preset}
                      className={`flex items-start gap-2.5 p-2.5 rounded-xl border text-xs cursor-pointer transition-colors ${
                        suspendReason === preset 
                          ? 'bg-rose-50/80 border-rose-300 text-rose-900 font-semibold' 
                          : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                      }`}
                    >
                      <input
                        type="radio"
                        name="violationReason"
                        checked={suspendReason === preset}
                        onChange={() => setSuspendReason(preset)}
                        className="mt-0.5 text-rose-600 focus:ring-rose-500"
                      />
                      <span>{preset}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Textarea if custom reason */}
              {suspendReason === 'Lainnya (Tulis Manual)' && (
                <div className="space-y-1.5 animate-in fade-in duration-150">
                  <label className="block text-xs font-bold text-slate-700">
                    Tulis Alasan Pelanggaran Spesifik:
                  </label>
                  <textarea
                    rows={2}
                    value={customReason}
                    onChange={(e) => setCustomReason(e.target.value)}
                    placeholder="Jelaskan detail kesalahan mitra..."
                    className="w-full p-2.5 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-rose-500"
                  />
                </div>
              )}

              {/* Countdown Preview Calculation */}
              <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-900 flex items-center gap-2">
                <Clock className="w-4 h-4 text-amber-600 shrink-0" />
                <div>
                  <p className="font-semibold">Masa Berlaku Hukuman:</p>
                  <p className="text-[11px] text-amber-800 mt-0.5">
                    Aktif mulai sekarang sampai: <strong>{new Date(Date.now() + 3 * 86400000).toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })} WIB</strong> (72 Jam).
                  </p>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-4 bg-slate-50 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                onClick={() => setSuspendModalTukang(null)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200 transition-colors"
              >
                Batal
              </button>
              <button
                onClick={handleApplySuspend}
                className="px-5 py-2 rounded-xl text-xs font-bold bg-rose-600 hover:bg-rose-700 text-white shadow-md shadow-rose-600/20 transition-all flex items-center gap-1.5"
              >
                <ShieldAlert className="w-4 h-4" />
                <span>Terapkan Suspend 3 Hari</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
