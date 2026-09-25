import React, { useState } from 'react';
import { 
  UserCheck, 
  Search, 
  CheckCircle2, 
  XCircle, 
  ShieldCheck, 
  Phone, 
  Wrench, 
  Briefcase
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
      t.phone.includes(searchQuery) ||
      (t.services && t.services.some(s => s.toLowerCase().includes(searchQuery.toLowerCase())));

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
      alert('Mohon tuliskan alasan penolakan pendaftaran.');
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
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Verifikasi Pendaftaran Mitra</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-100 text-blue-800">
              Mitra Onboarding Audit
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Verifikasi spesialisasi keahlian, nomor WhatsApp, dan data diri calon mitra sebelum diizinkan menerima pesanan.
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
            <span>Mitra Terverifikasi</span>
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

        {/* Search */}
        <div className="relative min-w-[280px]">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari nama, email, layanan, atau no. HP..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white text-slate-800"
          />
        </div>
      </div>

      {/* Table Section */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
        {filteredList.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-12 h-12 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mx-auto mb-3">
              <UserCheck className="w-6 h-6" />
            </div>
            <h3 className="text-sm font-bold text-slate-700">Tidak ada data pendaftaran mitra</h3>
            <p className="text-xs text-slate-400 mt-1">
              {activeTab === 'pending'
                ? 'Seluruh calon mitra sudah ditinjau dan diverifikasi.'
                : 'Tidak ada data mitra yang sesuai dengan pencarian ini.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 uppercase tracking-wider text-[11px]">
                <tr>
                  <th className="py-3.5 px-5">Calon Mitra</th>
                  <th className="py-3.5 px-4">Kontak WhatsApp</th>
                  <th className="py-3.5 px-4">Keahlian Layanan</th>
                  <th className="py-3.5 px-4">Metode Bayar</th>
                  <th className="py-3.5 px-4">Pengalaman / Bio</th>
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
                          className="w-10 h-10 rounded-xl object-cover ring-1 ring-slate-200" 
                        />
                        <div>
                          <p className="font-bold text-slate-900">{t.name}</p>
                          <p className="text-slate-400 text-[11px]">{t.email}</p>
                          <span className="inline-block mt-0.5 px-1.5 py-0.2 rounded bg-slate-100 text-slate-600 font-mono text-[10px]">
                            {t.id}
                          </span>
                        </div>
                      </div>
                    </td>

                    <td className="py-4 px-4 font-mono text-slate-700">
                      <div className="flex items-center gap-1.5">
                        <Phone className="w-3.5 h-3.5 text-emerald-600" />
                        <span className="font-semibold text-slate-900 text-xs">{t.phone}</span>
                      </div>
                      <p className="text-slate-400 font-sans text-[11px] mt-0.5">
                        {t.currentLocation?.address ? t.currentLocation.address.split(',')[0] : 'Jabodetabek'}
                      </p>
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
                      <span className="px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-700 font-semibold text-[10px] border border-emerald-100">
                        Tunai di Tempat (Cash)
                      </span>
                    </td>

                    <td className="py-4 px-4 max-w-[200px]">
                      <div className="space-y-0.5">
                        <span className="text-[11px] font-semibold text-slate-700 flex items-center gap-1">
                          <Briefcase className="w-3 h-3 text-slate-400" />
                          {t.experienceYears ? `${t.experienceYears} tahun pengalaman` : '3-5 tahun'}
                        </span>
                        <p className="text-[11px] text-slate-500 line-clamp-1">
                          {t.bio || 'Siap melayani pengerjaan sesuai bidang keahlian.'}
                        </p>
                      </div>
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
                          Aktif / Resmi
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
                        Tinjau Data
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Detail Inspeksi Mitra */}
      {selectedTukang && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-3xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
            {/* Modal Header */}
            <div className="p-6 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white z-10">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Verifikasi Kelayakan Calon Mitra</h3>
                <p className="text-xs text-slate-500">Periksa keabsahan kontak, spesialisasi, dan kesiapan operasional calon mitra</p>
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
              {/* Sisi Kiri: Profil & Kontak */}
              <div className="space-y-4">
                <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200/80 space-y-4">
                  <div className="flex items-center gap-4">
                    <img
                      src={selectedTukang.avatar}
                      alt={selectedTukang.name}
                      className="w-16 h-16 rounded-2xl object-cover ring-2 ring-blue-500/20 shadow-xs"
                    />
                    <div>
                      <h4 className="text-base font-bold text-slate-900">{selectedTukang.name}</h4>
                      <p className="text-xs text-slate-500">{selectedTukang.email}</p>
                      <span className="inline-block mt-1 px-2 py-0.5 rounded-full bg-blue-50 text-blue-700 text-[10px] font-semibold border border-blue-100">
                        {selectedTukang.id}
                      </span>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-slate-200/70 space-y-2.5">
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-slate-500">Nomor WhatsApp:</span>
                      <span className="font-bold text-slate-900 font-mono">{selectedTukang.phone}</span>
                    </div>

                    <div className="flex items-center justify-between text-xs">
                      <span className="text-slate-500">Area Domisili:</span>
                      <span className="font-semibold text-slate-700">
                        {selectedTukang.currentLocation?.address || 'DKI Jakarta'}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-xs">
                      <span className="text-slate-500">Pengalaman Kerja:</span>
                      <span className="font-bold text-slate-900">
                        {selectedTukang.experienceYears ? `${selectedTukang.experienceYears} Tahun` : '4+ Tahun'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Deskripsi Keahlian & Bio */}
                <div className="p-4 rounded-2xl bg-blue-50/50 border border-blue-100 space-y-1.5">
                  <span className="text-xs font-bold text-blue-900 flex items-center gap-1.5">
                    <Wrench className="w-3.5 h-3.5 text-blue-600" />
                    Deskripsi Kesiapan Kerja:
                  </span>
                  <p className="text-xs text-blue-900/80 leading-relaxed">
                    {selectedTukang.bio || 'Mitra siap membawa peralatan pendukung mandiri dan sanggup datang sesuai jam perjanjian konsumen.'}
                  </p>
                </div>

                {/* Checklist Verifikasi */}
                <div className="p-4 rounded-2xl bg-emerald-50/60 border border-emerald-200 text-xs text-emerald-900 space-y-1.5">
                  <span className="font-bold flex items-center gap-1.5 text-emerald-900">
                    <ShieldCheck className="w-4 h-4 text-emerald-600" />
                    Ketentuan Persetujuan Admin:
                  </span>
                  <ul className="list-disc list-inside text-[11px] text-emerald-800 space-y-1">
                    <li>Nomor WhatsApp aktif dan dapat dihubungi pelanggan.</li>
                    <li>Kategori layanan sesuai dengan kemampuan nyata mitra.</li>
                    <li>Metode transaksi dilakukan langsung secara tunai (Pure Cash) di lokasi konsumen.</li>
                  </ul>
                </div>
              </div>

              {/* Sisi Kanan: Metode Transaksi & Layanan */}
              <div className="space-y-4">
                <span className="text-xs font-bold text-slate-700 uppercase tracking-wide block">
                  Kategori Layanan & Metode Pembayaran
                </span>

                {/* Services Pills */}
                <div className="bg-slate-50 rounded-2xl p-4 border border-slate-200/80 space-y-2">
                  <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider block">
                    Kategori Jasa Yang Diberikan:
                  </span>
                  <div className="flex flex-wrap gap-1.5">
                    {selectedTukang.services.map(s => (
                      <span key={s} className="px-2.5 py-1 rounded-lg bg-white border border-slate-200 text-slate-800 font-bold text-xs uppercase shadow-2xs">
                        {s}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Metode Pembayaran */}
                <div className="bg-slate-50 rounded-2xl p-4 border border-slate-200/80 space-y-2">
                  <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider block">
                    Metode Pembayaran Transaksi:
                  </span>
                  <div className="bg-white p-3 rounded-xl border border-slate-200 shadow-2xs">
                    <p className="text-xs text-slate-800 font-semibold flex items-center gap-1.5">
                      <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                      Tunai Langsung di Tempat (Pure Cash)
                    </p>
                    <p className="text-[11px] text-slate-500 mt-1">
                      Mitra menerima uang tunai langsung dari konsumen setelah pekerjaan selesai diverifikasi. Tidak ada pemotongan komisi/saldo.
                    </p>
                  </div>
                </div>

                {/* Form Alasan Tolak */}
                {showRejectForm && (
                  <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 space-y-3 animate-in fade-in duration-150">
                    <label className="block text-xs font-bold text-rose-900">
                      Tuliskan Alasan Penolakan Pendaftaran:
                    </label>
                    <textarea
                      rows={2}
                      placeholder="Contoh: Nomor telepon tidak aktif atau foto dokumen KTP kurang jelas."
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      className="w-full p-2.5 text-xs rounded-lg border border-rose-300 bg-white focus:outline-none focus:ring-2 focus:ring-rose-500 text-slate-900"
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleReject(selectedTukang.id)}
                        className="px-3 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs"
                      >
                        Konfirmasi Tolak
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
                    Tolak Pendaftaran
                  </button>
                )}

                <button
                  onClick={() => handleApprove(selectedTukang.id)}
                  className="px-6 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-600/20 transition-all flex items-center gap-1.5"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Setujui Mitra (Aktifkan Akun)</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
