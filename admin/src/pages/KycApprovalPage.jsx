import React, { useState } from 'react';
import { 
  UserCheck, 
  Search, 
  CheckCircle2, 
  XCircle, 
  Eye, 
  Calendar, 
  CreditCard, 
  AlertCircle,
  ZoomIn,
  ShieldCheck,
  ShieldAlert,
  ArrowRight
} from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

export default function KycApprovalPage() {
  const { tukangList, approveKyc, rejectKyc } = useAdminData();
  const [activeTab, setActiveTab] = useState('pending'); // 'pending' | 'verified' | 'rejected'
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTukang, setSelectedTukang] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectForm, setShowRejectForm] = useState(false);

  const filteredList = tukangList.filter(t => {
    const matchesTab = 
      activeTab === 'pending' ? t.verificationStatus === 'pending_verification' :
      activeTab === 'verified' ? t.verificationStatus === 'verified' :
      t.verificationStatus === 'rejected';

    const matchesSearch = 
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.ktpNik && t.ktpNik.includes(searchQuery));

    return matchesTab && matchesSearch;
  });

  const pendingCount = tukangList.filter(t => t.verificationStatus === 'pending_verification').length;
  const verifiedCount = tukangList.filter(t => t.verificationStatus === 'verified').length;
  const rejectedCount = tukangList.filter(t => t.verificationStatus === 'rejected').length;

  const handleApprove = (tukangId) => {
    approveKyc(tukangId);
    setSelectedTukang(null);
  };

  const handleReject = (tukangId) => {
    if (!rejectReason.trim()) {
      alert('Mohon isi alasan penolakan KTP.');
      return;
    }
    rejectKyc(tukangId, rejectReason);
    setSelectedTukang(null);
    setShowRejectForm(false);
    setRejectReason('');
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Verifikasi KTP Mitra (KYC)</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-100 text-blue-800">
              Trust & Safety
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Verifikasi identitas KTP tukang sebelum diizinkan menerima order dan bekerja di rumah pelanggan.
          </p>
        </div>
      </div>

      {/* Tabs & Search Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
        {/* Filter Tabs */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveTab('pending')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'pending'
                ? 'bg-amber-500 text-white shadow-sm shadow-amber-500/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Menunggu Review</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'pending' ? 'bg-amber-600 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {pendingCount}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('verified')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'verified'
                ? 'bg-emerald-600 text-white shadow-sm shadow-emerald-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Terverifikasi</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'verified' ? 'bg-emerald-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {verifiedCount}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('rejected')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'rejected'
                ? 'bg-rose-600 text-white shadow-sm shadow-rose-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Ditolak</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'rejected' ? 'bg-rose-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {rejectedCount}
            </span>
          </button>
        </div>

        {/* Search Input */}
        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari nama, email, atau NIK..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
          />
        </div>
      </div>

      {/* KYC Table */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
        {filteredList.length === 0 ? (
          <div className="py-16 text-center">
            <CheckCircle2 className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-700">Tidak ada data tukang di kategori ini</p>
            <p className="text-xs text-slate-400 mt-1">Semua dokumen KTP telah selesai diproses.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 uppercase tracking-wider text-[11px]">
                <tr>
                  <th className="py-3.5 px-5">Calon Mitra</th>
                  <th className="py-3.5 px-4">NIK & Usia</th>
                  <th className="py-3.5 px-4">Keahlian Layanan</th>
                  <th className="py-3.5 px-4">Rekening Payout</th>
                  <th className="py-3.5 px-4">Foto KTP</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-5 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredList.map((t) => (
                  <tr key={t.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 px-5">
                      <div className="flex items-center gap-3">
                        <img 
                          src={t.avatar} 
                          alt={t.name} 
                          className="w-9 h-9 rounded-xl object-cover ring-1 ring-slate-200" 
                        />
                        <div>
                          <p className="font-bold text-slate-900">{t.name}</p>
                          <p className="text-slate-400 text-[11px]">{t.email}</p>
                          <p className="text-slate-500 text-[10px] mt-0.5">{t.phone}</p>
                        </div>
                      </div>
                    </td>

                    <td className="py-4 px-4 font-mono text-slate-700">
                      <p className="font-semibold text-slate-900">{t.ktpNik || '-'}</p>
                      <p className="text-slate-500 font-sans text-[11px]">{t.birthDate} ({t.age} tahun)</p>
                    </td>

                    <td className="py-4 px-4">
                      <div className="flex flex-wrap gap-1 max-w-xs">
                        {t.services.map(s => (
                          <span key={s} className="px-2 py-0.5 rounded-md bg-blue-50 text-blue-700 font-semibold text-[10px] uppercase border border-blue-100">
                            {s}
                          </span>
                        ))}
                      </div>
                    </td>

                    <td className="py-4 px-4">
                      <div className="space-y-1">
                        {t.payoutAccounts?.map((acc, idx) => (
                          <div key={idx} className="text-[11px] text-slate-700 flex items-center gap-1.5">
                            <span className="font-bold px-1.5 py-0.2 rounded bg-slate-100 text-slate-800 text-[10px]">
                              {acc.provider}
                            </span>
                            <span className="font-mono text-[11px]">{acc.accountNumber}</span>
                          </div>
                        ))}
                      </div>
                    </td>

                    <td className="py-4 px-4">
                      <button
                        onClick={() => setSelectedTukang(t)}
                        className="group relative block w-16 h-10 rounded-lg overflow-hidden border border-slate-200 shadow-xs hover:ring-2 hover:ring-blue-500 transition-all"
                      >
                        <img 
                          src={t.ktpUrl} 
                          alt="Thumbnail KTP" 
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform" 
                        />
                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white transition-opacity">
                          <Eye className="w-3.5 h-3.5" />
                        </div>
                      </button>
                    </td>

                    <td className="py-4 px-4">
                      {t.verificationStatus === 'pending_verification' ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 text-[11px] font-semibold">
                          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                          Menunggu
                        </span>
                      ) : t.verificationStatus === 'verified' ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                          <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                          Terverifikasi
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-50 text-rose-700 border border-rose-200 text-[11px] font-semibold">
                          <XCircle className="w-3 h-3 text-rose-600" />
                          Ditolak
                        </span>
                      )}
                    </td>

                    <td className="py-4 px-5 text-right">
                      <button
                        onClick={() => setSelectedTukang(t)}
                        className="px-3.5 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-white font-semibold text-xs transition-colors shadow-xs"
                      >
                        Inspeksi Dokumen
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Detail Inspeksi KTP */}
      {selectedTukang && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-4xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
            {/* Modal Header */}
            <div className="p-6 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white z-10">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Inspeksi & Verifikasi KTP Mitra</h3>
                <p className="text-xs text-slate-500">Bandingkan foto identitas fisik dengan data pendaftaran</p>
              </div>
              <button
                onClick={() => {
                  setSelectedTukang(null);
                  setShowRejectForm(false);
                }}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center font-bold text-sm"
              >
                ✕
              </button>
            </div>

            <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Sisi Kiri: Foto KTP Resolusi Tinggi */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-700 uppercase tracking-wide">Lampiran Foto KTP</span>
                  <span className="text-[11px] text-blue-600 font-semibold flex items-center gap-1">
                    <ZoomIn className="w-3.5 h-3.5" /> High Resolution
                  </span>
                </div>

                <div className="rounded-2xl overflow-hidden border border-slate-200 bg-slate-900 p-1 group relative shadow-inner">
                  <img
                    src={selectedTukang.ktpUrl}
                    alt="Foto KTP Asli"
                    className="w-full h-64 object-contain rounded-xl"
                  />
                  <div className="absolute bottom-3 left-3 bg-black/70 backdrop-blur-md px-3 py-1 rounded-lg text-white text-[11px] font-mono">
                    NIK Terbaca: {selectedTukang.ktpNik || 'Manual Review'}
                  </div>
                </div>

                <div className="bg-blue-50/60 border border-blue-200 rounded-xl p-3 text-xs text-blue-800 space-y-1">
                  <p className="font-semibold flex items-center gap-1.5">
                    <ShieldCheck className="w-4 h-4 text-blue-600" />
                    Panduan Verifikasi Keamanan:
                  </p>
                  <ul className="list-disc list-inside text-[11px] text-blue-700/90 space-y-0.5">
                    <li>Pastikan foto KTP tidak buram, pantulan flash tidak menutupi tulisan.</li>
                    <li>Nama harus sesuai dengan nama rekening bank / e-wallet pencairan.</li>
                    <li>Usia minimal mitra adalah 18 tahun.</li>
                  </ul>
                </div>
              </div>

              {/* Sisi Kanan: Data Profil Mitra */}
              <div className="space-y-4">
                <span className="text-xs font-bold text-slate-700 uppercase tracking-wide block">
                  Data Registrasi Sistem
                </span>

                <div className="bg-slate-50 rounded-2xl p-4 border border-slate-200/80 space-y-3">
                  <div>
                    <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">Nama Lengkap</span>
                    <p className="text-sm font-bold text-slate-900">{selectedTukang.name}</p>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">NIK KTP</span>
                      <p className="text-xs font-mono font-bold text-slate-900">{selectedTukang.ktpNik || '-'}</p>
                    </div>
                    <div>
                      <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">Tanggal Lahir / Usia</span>
                      <p className="text-xs font-bold text-slate-900">{selectedTukang.birthDate} ({selectedTukang.age} thn)</p>
                    </div>
                  </div>

                  <div>
                    <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">Nomor Kontak WhatsApp</span>
                    <p className="text-xs font-bold text-slate-900">{selectedTukang.phone}</p>
                  </div>

                  <div>
                    <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">Akun Rekening Pencairan Dana</span>
                    <div className="mt-1 space-y-1">
                      {selectedTukang.payoutAccounts?.map((acc, i) => (
                        <div key={i} className="flex items-center justify-between text-xs bg-white p-2 rounded-lg border border-slate-200">
                          <span className="font-bold text-slate-800">{acc.provider}</span>
                          <span className="font-mono text-slate-600">{acc.accountNumber}</span>
                          <span className="text-[11px] text-slate-500">a.n {acc.accountName}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div>
                    <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">Keahlian Layanan</span>
                    <div className="flex flex-wrap gap-1.5 mt-1">
                      {selectedTukang.services.map(s => (
                        <span key={s} className="px-2 py-0.5 rounded-md bg-white border border-slate-200 text-slate-800 font-semibold text-[11px] uppercase">
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Form Alasan Tolak */}
                {showRejectForm && (
                  <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 space-y-3 animate-in fade-in duration-150">
                    <label className="block text-xs font-bold text-rose-900">
                      Tuliskan Alasan Penolakan KTP:
                    </label>
                    <textarea
                      rows={2}
                      placeholder="Contoh: Foto KTP terlalu buram, mohon foto ulang dengan pencahayaan terang."
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      className="w-full p-2.5 text-xs rounded-lg border border-rose-300 bg-white focus:outline-none focus:ring-2 focus:ring-rose-500 text-slate-900"
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleReject(selectedTukang.id)}
                        className="px-3 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs"
                      >
                        Konfirmasi Tolak KTP
                      </button>
                      <button
                        onClick={() => setShowRejectForm(false)}
                        className="px-3 py-1.5 rounded-lg bg-slate-200 text-slate-700 font-semibold text-xs"
                      >
                        Batal
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Modal Footer Actions */}
            <div className="p-6 border-t border-slate-100 bg-slate-50 rounded-b-3xl flex items-center justify-between">
              <div>
                <span className="text-xs text-slate-500">Status saat ini: </span>
                <strong className="text-xs text-slate-800 capitalize">
                  {selectedTukang.verificationStatus.replace('_', ' ')}
                </strong>
              </div>

              <div className="flex items-center gap-3">
                {!showRejectForm && (
                  <button
                    onClick={() => setShowRejectForm(true)}
                    className="px-4 py-2 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 text-xs font-bold transition-colors"
                  >
                    Tolak Dokumen
                  </button>
                )}

                <button
                  onClick={() => handleApprove(selectedTukang.id)}
                  className="px-6 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-600/20 transition-all flex items-center gap-1.5"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Setujui Mitra (Approve)</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
