import React, { useState } from 'react';
import { 
  WalletCards, 
  Search, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  ArrowRight, 
  ShieldCheck,
  Building2
} from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

export default function WithdrawalPage() {
  const { withdrawalsList, approveWithdrawal, rejectWithdrawal } = useAdminData();
  const [selectedWithdrawal, setSelectedWithdrawal] = useState(null);
  const [adminNote, setAdminNote] = useState('');
  const [activeTab, setActiveTab] = useState('ALL'); // 'ALL' | 'PENDING' | 'APPROVED' | 'REJECTED'
  const [searchQuery, setSearchQuery] = useState('');

  const filteredWithdrawals = withdrawalsList.filter(w => {
    const matchesTab = 
      activeTab === 'ALL' ? true :
      activeTab === 'PENDING' ? w.status === 'pending' :
      activeTab === 'APPROVED' ? w.status === 'approved' :
      w.status === 'rejected';

    const matchesSearch = 
      w.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.tukangName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.payoutTarget.provider.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.payoutTarget.accountNumber.includes(searchQuery);

    return matchesTab && matchesSearch;
  });

  const pendingList = withdrawalsList.filter(w => w.status === 'pending');
  const approvedList = withdrawalsList.filter(w => w.status === 'approved');
  const rejectedList = withdrawalsList.filter(w => w.status === 'rejected');

  const pendingTotal = pendingList.reduce((acc, curr) => acc + curr.amount, 0);
  const approvedTotal = approvedList.reduce((acc, curr) => acc + curr.amount, 0);

  const handleApprove = (id) => {
    approveWithdrawal(id, adminNote || 'Transfer manual via m-Banking terkonfirmasi');
    setSelectedWithdrawal(null);
    setAdminNote('');
  };

  const handleReject = (id) => {
    if (!adminNote.trim()) {
      alert('Mohon tulis alasan penolakan pencairan dana.');
      return;
    }
    rejectWithdrawal(id, adminNote);
    setSelectedWithdrawal(null);
    setAdminNote('');
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Pencairan Dana Dompet Mitra</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800">
              Payout Ledger
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Konfirmasi dan proses transfer penarikan saldo dompet tukang ke rekening bank atau e-wallet terdaftar secara aman.
          </p>
        </div>
      </div>

      {/* Top Stat Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs text-slate-400 font-semibold block">Menunggu Transfer</span>
            <span className="text-xl font-bold text-slate-900 font-mono mt-0.5 block">
              Rp {pendingTotal.toLocaleString('id-ID')}
            </span>
            <span className="text-[11px] text-amber-600 font-semibold mt-1 inline-block">
              {pendingList.length} pengajuan antre
            </span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs text-slate-400 font-semibold block">Total Berhasil Ditransfer</span>
            <span className="text-xl font-bold text-emerald-600 font-mono mt-0.5 block">
              Rp {approvedTotal.toLocaleString('id-ID')}
            </span>
            <span className="text-[11px] text-emerald-700 font-semibold mt-1 inline-block">
              {approvedList.length} penarikan sukses
            </span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs text-slate-400 font-semibold block">Kebijakan Payout</span>
            <span className="text-sm font-bold text-slate-800 block mt-0.5">
              0% Fee Penarikan
            </span>
            <span className="text-[11px] text-slate-500 mt-1 inline-block">
              BCA, Mandiri, BRI, BNI & E-Wallet
            </span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <Building2 className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Tabs & Search Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
        {/* Status Tabs */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveTab('ALL')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'ALL'
                ? 'bg-slate-900 text-white shadow-xs'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Semua ({withdrawalsList.length})
          </button>

          <button
            onClick={() => setActiveTab('PENDING')}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'PENDING'
                ? 'bg-amber-500 text-white shadow-xs shadow-amber-500/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Menunggu Transfer</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'PENDING' ? 'bg-amber-600 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {pendingList.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('APPROVED')}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'APPROVED'
                ? 'bg-emerald-600 text-white shadow-xs shadow-emerald-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Selesai Ditransfer</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'APPROVED' ? 'bg-emerald-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {approvedList.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('REJECTED')}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'REJECTED'
                ? 'bg-rose-600 text-white shadow-xs shadow-rose-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Ditolak</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'REJECTED' ? 'bg-rose-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {rejectedList.length}
            </span>
          </button>
        </div>

        {/* Search */}
        <div className="relative min-w-[280px]">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari ID payout, nama mitra, atau rekening..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white text-slate-800"
          />
        </div>
      </div>

      {/* Table Section */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
        {filteredWithdrawals.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-12 h-12 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mx-auto mb-3">
              <WalletCards className="w-6 h-6" />
            </div>
            <h3 className="text-sm font-bold text-slate-700">Tidak ada data penarikan saldo</h3>
            <p className="text-xs text-slate-400 mt-1">Belum ada pengajuan pencairan yang cocok dengan filter ini.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 uppercase tracking-wider text-[11px]">
                <tr>
                  <th className="py-3.5 px-5">ID Payout</th>
                  <th className="py-3.5 px-4">Nama Mitra</th>
                  <th className="py-3.5 px-4">Jumlah Penarikan</th>
                  <th className="py-3.5 px-4">Tujuan Rekening / E-Wallet</th>
                  <th className="py-3.5 px-4">Waktu Pengajuan</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-5 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredWithdrawals.map((w) => (
                  <tr key={w.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 px-5 font-mono font-bold text-slate-900">#{w.id}</td>
                    <td className="py-4 px-4 font-bold text-slate-900">{w.tukangName}</td>
                    <td className="py-4 px-4 font-bold text-slate-900 font-mono text-sm">
                      Rp {w.amount.toLocaleString('id-ID')}
                    </td>
                    <td className="py-4 px-4">
                      <div className="text-xs">
                        <span className="font-bold px-1.5 py-0.2 rounded bg-slate-100 text-slate-800 text-[10px] mr-1.5">
                          {w.payoutTarget.provider}
                        </span>
                        <span className="font-mono">{w.payoutTarget.accountNumber}</span>
                        <p className="text-[11px] text-slate-500 mt-0.5">a.n {w.payoutTarget.accountName}</p>
                      </div>
                    </td>
                    <td className="py-4 px-4 text-slate-500">{w.requestedAt}</td>
                    <td className="py-4 px-4">
                      {w.status === 'pending' ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 text-[11px] font-semibold">
                          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                          Menunggu Transfer
                        </span>
                      ) : w.status === 'approved' ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                          <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                          Ditransfer
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-50 text-rose-700 border border-rose-200 text-[11px] font-semibold">
                          <XCircle className="w-3 h-3 text-rose-600" />
                          Ditolak
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-5 text-right">
                      {w.status === 'pending' ? (
                        <button
                          onClick={() => setSelectedWithdrawal(w)}
                          className="px-3.5 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-xs"
                        >
                          Proses Transfer
                        </button>
                      ) : (
                        <div className="text-right">
                          <span className="text-slate-400 text-[11px] block">{w.processedAt || 'Telah diproses'}</span>
                          {w.adminNote && (
                            <span className="text-slate-500 text-[10px] italic block truncate max-w-[180px]">"{w.adminNote}"</span>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Payout Approval */}
      {selectedWithdrawal && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full shadow-2xl border border-slate-200 p-6 space-y-4 animate-in fade-in zoom-in-95 duration-200">
            <h3 className="text-base font-bold text-slate-900">Konfirmasi Transfer Pencairan Dana</h3>
            
            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 text-xs space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-500">Mitra Pemohon:</span>
                <strong className="text-slate-900">{selectedWithdrawal.tukangName}</strong>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Nominal Penarikan:</span>
                <strong className="text-emerald-700 font-mono text-sm">Rp {selectedWithdrawal.amount.toLocaleString('id-ID')}</strong>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Rekening Tujuan:</span>
                <span className="font-mono text-slate-900 font-bold">{selectedWithdrawal.payoutTarget.provider} - {selectedWithdrawal.payoutTarget.accountNumber}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Nama Pemilik:</span>
                <span className="text-slate-900 font-bold">{selectedWithdrawal.payoutTarget.accountName}</span>
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-700">Catatan Admin / Referensi Mutasi Bank:</label>
              <input
                type="text"
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                placeholder="Contoh: Transfer via BCA KlikBisnis Ref #88921"
                className="w-full p-2.5 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-slate-900"
              />
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                onClick={() => setSelectedWithdrawal(null)}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
              >
                Tutup
              </button>
              <button
                onClick={() => handleReject(selectedWithdrawal.id)}
                className="px-4 py-2 text-xs font-bold text-rose-700 bg-rose-50 hover:bg-rose-100 rounded-xl border border-rose-200"
              >
                Tolak
              </button>
              <button
                onClick={() => handleApprove(selectedWithdrawal.id)}
                className="px-5 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-md shadow-emerald-600/20"
              >
                Setujui & Tandai Ditransfer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
