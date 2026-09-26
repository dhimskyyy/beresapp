import React, { useState } from 'react';
import { 
  ClipboardList, 
  Search, 
  Camera, 
  Receipt,
  User,
  Wrench,
  Star
} from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

export default function TicketMonitorPage() {
  const { ticketsList } = useAdminData();
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [filterCategory, setFilterCategory] = useState('ALL');
  const [filterStatus, setFilterStatus] = useState('ALL'); // 'ALL' | 'ACTIVE' | 'COMPLETED' | 'CANCELED'
  const [searchQuery, setSearchQuery] = useState('');

  const filteredTickets = ticketsList.filter(t => {
    const matchesCat = filterCategory === 'ALL' || t.category === filterCategory;
    const matchesStatus = 
      filterStatus === 'ALL' ? true :
      filterStatus === 'ACTIVE' ? (t.status !== 'COMPLETED' && t.status !== 'CANCELED') :
      filterStatus === 'COMPLETED' ? t.status === 'COMPLETED' :
      t.status === 'CANCELED';

    const matchesSearch = 
      t.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.userName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.selectedTukangName && t.selectedTukangName.toLowerCase().includes(searchQuery.toLowerCase()));

    return matchesCat && matchesStatus && matchesSearch;
  });

  const activeCount = ticketsList.filter(t => t.status !== 'COMPLETED' && t.status !== 'CANCELED').length;
  const completedCount = ticketsList.filter(t => t.status === 'COMPLETED').length;
  const canceledCount = ticketsList.filter(t => t.status === 'CANCELED').length;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Monitoring Tiket & Audit Pekerjaan</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-100 text-blue-800">
              Live Operations
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Pantau seluruh progres pekerjaan dari keluhan user, foto sebelum/sesudah pengerjaan, nota tagihan, hingga review bintang konsumen.
          </p>
        </div>

        {/* Category Filter Dropdown */}
        <select
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
          className="text-xs font-semibold bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-slate-700 shadow-xs focus:outline-none"
        >
          <option value="ALL">Semua Kategori Jasa</option>
          <option value="ac">Servis AC</option>
          <option value="plumbing">Plumbing & Pipa</option>
          <option value="las">Teralis & Las</option>
          <option value="cleaning">Home Cleaning</option>
          <option value="elektronik">Elektronik</option>
          <option value="bangunan">Renovasi Bangunan</option>
        </select>
      </div>

      {/* Filter Tabs & Search Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
        {/* Status Tabs */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setFilterStatus('ALL')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              filterStatus === 'ALL'
                ? 'bg-slate-900 text-white shadow-xs'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Semua ({ticketsList.length})
          </button>

          <button
            onClick={() => setFilterStatus('ACTIVE')}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              filterStatus === 'ACTIVE'
                ? 'bg-blue-600 text-white shadow-xs shadow-blue-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Sedang Berjalan</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${filterStatus === 'ACTIVE' ? 'bg-blue-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {activeCount}
            </span>
          </button>

          <button
            onClick={() => setFilterStatus('COMPLETED')}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              filterStatus === 'COMPLETED'
                ? 'bg-emerald-600 text-white shadow-xs shadow-emerald-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Selesai & Lunas</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${filterStatus === 'COMPLETED' ? 'bg-emerald-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {completedCount}
            </span>
          </button>

          <button
            onClick={() => setFilterStatus('CANCELED')}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              filterStatus === 'CANCELED'
                ? 'bg-rose-600 text-white shadow-xs shadow-rose-600/20'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>Dibatalkan</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${filterStatus === 'CANCELED' ? 'bg-rose-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {canceledCount}
            </span>
          </button>
        </div>

        {/* Search Box */}
        <div className="relative min-w-[260px]">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari ID tiket, user, judul, tukang..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white text-slate-800"
          />
        </div>
      </div>

      {/* Grid of Ticket Cards */}
      {filteredTickets.length === 0 ? (
        <div className="bg-white rounded-2xl border border-slate-200/80 p-12 text-center shadow-xs">
          <div className="w-12 h-12 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mx-auto mb-3">
            <ClipboardList className="w-6 h-6" />
          </div>
          <h3 className="text-sm font-bold text-slate-700">Tidak ada tiket yang cocok</h3>
          <p className="text-xs text-slate-400 mt-1">Coba sesuaikan filter status, kategori, atau kata kunci pencarian Anda.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredTickets.map(ticket => (
            <div 
              key={ticket.id} 
              className="bg-white rounded-2xl border border-slate-200/80 shadow-xs hover:shadow-md transition-all overflow-hidden flex flex-col justify-between"
            >
              <div className="p-5 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-400 font-mono">#{ticket.id}</span>
                  <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full ${
                    ticket.status === 'COMPLETED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                    ticket.status === 'ON_THE_WAY' ? 'bg-blue-50 text-blue-700 border border-blue-200' :
                    ticket.status === 'CANCELED' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                    'bg-amber-50 text-amber-700 border border-amber-200'
                  }`}>
                    {ticket.statusLabel}
                  </span>
                </div>

                <div>
                  <span className="text-[10px] font-bold uppercase tracking-wider text-blue-600 bg-blue-50 px-2 py-0.5 rounded">
                    {ticket.categoryLabel}
                  </span>
                  <h3 className="text-sm font-bold text-slate-900 mt-1 line-clamp-1">{ticket.title}</h3>
                  <p className="text-xs text-slate-500 line-clamp-2 mt-1">{ticket.description}</p>
                </div>

                {/* Photos Previews */}
                <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                  <div className="flex -space-x-2 overflow-hidden">
                    {ticket.issuePhotos?.map((url, i) => (
                      <img key={i} src={url} alt="Issue" className="inline-block h-9 w-9 rounded-lg object-cover ring-2 ring-white" />
                    ))}
                    {ticket.beforePhotos?.map((url, i) => (
                      <img key={i} src={url} alt="Before" className="inline-block h-9 w-9 rounded-lg object-cover ring-2 ring-amber-400" title="Foto Sebelum Kerja" />
                    ))}
                    {ticket.afterPhotos?.map((url, i) => (
                      <img key={i} src={url} alt="After" className="inline-block h-9 w-9 rounded-lg object-cover ring-2 ring-emerald-400" title="Foto Setelah Kerja" />
                    ))}
                  </div>
                  <span className="text-[11px] text-slate-400 font-medium">
                    {(ticket.beforePhotos?.length || 0) + (ticket.afterPhotos?.length || 0) > 0 ? 'Bukti Foto Ada' : 'Foto Awal'}
                  </span>
                </div>

                {/* Consumer Rating preview if completed */}
                {ticket.rating && (
                  <div className="pt-2 border-t border-slate-100 flex items-center gap-1.5 text-xs">
                    <div className="flex text-amber-400">
                      {[...Array(ticket.rating.stars || 5)].map((_, i) => (
                        <Star key={i} className="w-3.5 h-3.5 fill-current" />
                      ))}
                    </div>
                    <span className="font-bold text-slate-800">{ticket.rating.stars}.0</span>
                    <span className="text-slate-400 text-[11px] truncate">"{ticket.rating.review}"</span>
                  </div>
                )}

                <div className="text-xs text-slate-500 space-y-1 pt-1">
                  <p className="flex items-center gap-1.5 truncate">
                    <User className="w-3.5 h-3.5 text-slate-400" />
                    <span>Pelanggan: <strong className="text-slate-700">{ticket.userName}</strong></span>
                  </p>
                  <p className="flex items-center gap-1.5 truncate">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span>Tukang: <strong className="text-slate-700">{ticket.selectedTukangName || 'Belum dipilih'}</strong></span>
                  </p>
                </div>
              </div>

              <div className="p-4 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-slate-400 uppercase font-semibold">Total Biaya</span>
                  <p className="text-xs font-bold text-slate-900 font-mono">
                    {ticket.finalBill 
                      ? `Rp ${ticket.finalBill.totalAmount.toLocaleString('id-ID')}` 
                      : (ticket.bids?.[0] ? `Est. Rp ${ticket.bids[0].estimatedPrice.toLocaleString('id-ID')}` : '-')}
                  </p>
                </div>

                <button
                  onClick={() => setSelectedTicket(ticket)}
                  className="px-3 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold shadow-xs"
                >
                  Detail Tiket
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Detail Tiket & Foto Before/After & Review */}
      {selectedTicket && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white z-10">
              <div>
                <span className="text-xs font-bold text-slate-400 font-mono">#{selectedTicket.id}</span>
                <h3 className="text-base font-bold text-slate-900">{selectedTicket.title}</h3>
              </div>
              <button
                onClick={() => setSelectedTicket(null)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center font-bold"
              >
                ✕
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* Lokasi & Pelanggan */}
              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 grid grid-cols-2 gap-4 text-xs">
                <div>
                  <span className="text-slate-400 font-medium">Pelanggan:</span>
                  <p className="font-bold text-slate-900 mt-0.5">{selectedTicket.userName} ({selectedTicket.userPhone})</p>
                  <p className="text-slate-500 mt-1">{selectedTicket.address}</p>
                </div>
                <div>
                  <span className="text-slate-400 font-medium">Tukang Terpilih:</span>
                  <p className="font-bold text-slate-900 mt-0.5">{selectedTicket.selectedTukangName || 'Belum di-lock'}</p>
                  <p className="text-slate-500 mt-1">Status: <strong>{selectedTicket.statusLabel}</strong></p>
                </div>
              </div>

              {/* Ulasan & Rating Bintang Konsumen */}
              {selectedTicket.rating && (
                <div className="p-4 rounded-2xl bg-amber-50/70 border border-amber-200 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-amber-950 uppercase tracking-wide flex items-center gap-1.5">
                      <Star className="w-4 h-4 text-amber-600 fill-current" />
                      Penilaian & Ulasan Konsumen
                    </span>
                    <div className="flex text-amber-500">
                      {[...Array(selectedTicket.rating.stars || 5)].map((_, i) => (
                        <Star key={i} className="w-4 h-4 fill-current" />
                      ))}
                    </div>
                  </div>
                  <p className="text-xs text-amber-900 italic bg-white/80 p-3 rounded-xl border border-amber-200">
                    "{selectedTicket.rating.review}"
                  </p>
                </div>
              )}

              {/* Rincian Tagihan Final */}
              {selectedTicket.finalBill && (
                <div className="space-y-2">
                  <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wide flex items-center gap-1.5">
                    <Receipt className="w-4 h-4 text-slate-500" />
                    Rincian Tagihan Nota Final (Di-acc User)
                  </h4>
                  <div className="border border-slate-200 rounded-xl overflow-hidden text-xs">
                    {selectedTicket.finalBill.items.map((item, idx) => (
                      <div key={idx} className="flex justify-between p-3 border-b border-slate-100 last:border-0">
                        <span className="text-slate-700">{item.title}</span>
                        <span className="font-bold text-slate-900 font-mono">Rp {item.amount.toLocaleString('id-ID')}</span>
                      </div>
                    ))}
                    <div className="flex justify-between p-3 bg-slate-50 font-bold border-t border-slate-200">
                      <span>Total Tagihan Akhir (Tunai Langsung)</span>
                      <span className="text-emerald-700 font-mono">Rp {(selectedTicket.finalBill?.totalAmount || 0).toLocaleString('id-ID')}</span>
                    </div>
                  </div>
                </div>
              )}

              {/* Inspeksi Foto Before & After */}
              <div className="space-y-3">
                <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wide flex items-center gap-1.5">
                  <Camera className="w-4 h-4 text-slate-500" />
                  Perbandingan Foto Sebelum & Sesudah Pengerjaan
                </h4>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-[11px] font-bold text-amber-800 bg-amber-50 px-2 py-0.5 rounded border border-amber-200 mb-2 inline-block">
                      Foto Sebelum Pengerjaan
                    </span>
                    {selectedTicket.beforePhotos && selectedTicket.beforePhotos.length > 0 ? (
                      <img src={selectedTicket.beforePhotos[0]} alt="Before" className="w-full h-44 object-cover rounded-xl border border-slate-200 shadow-xs" />
                    ) : (
                      <div className="h-44 rounded-xl border border-dashed border-slate-200 flex items-center justify-center text-xs text-slate-400">
                        Belum diunggah
                      </div>
                    )}
                  </div>

                  <div>
                    <span className="text-[11px] font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200 mb-2 inline-block">
                      Foto Sesudah Pengerjaan
                    </span>
                    {selectedTicket.afterPhotos && selectedTicket.afterPhotos.length > 0 ? (
                      <img src={selectedTicket.afterPhotos[0]} alt="After" className="w-full h-44 object-cover rounded-xl border border-slate-200 shadow-xs" />
                    ) : (
                      <div className="h-44 rounded-xl border border-dashed border-slate-200 flex items-center justify-center text-xs text-slate-400">
                        Belum diunggah
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
