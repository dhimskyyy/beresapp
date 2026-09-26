import React, { useState } from 'react';
import { Users, Search, ShoppingBag, MapPin, Calendar, CheckCircle2, Trash2 } from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

const DEFAULT_AVATAR = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80';

export default function UserListPage() {
  const { usersList, ticketsList, dataLoading, deleteUser } = useAdminData();
  const [searchQuery, setSearchQuery] = useState('');

  const filteredUsers = (usersList || []).filter(u => {
    const q = searchQuery.toLowerCase();
    const nameMatch = (u?.name || '').toLowerCase().includes(q);
    const emailMatch = (u?.email || '').toLowerCase().includes(q);
    const phoneMatch = (u?.phone || '').includes(searchQuery);
    return nameMatch || emailMatch || phoneMatch;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Daftar Pengguna (Pelanggan)</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-700">
              Total {usersList?.length || 0} User
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Data profil pelanggan yang mencari dan memesan jasa tukang melalui aplikasi Beres.
          </p>
        </div>
      </div>

      <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari nama pelanggan, nomor HP, email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          />
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 uppercase tracking-wider text-[11px]">
              <tr>
                <th className="py-3.5 px-5">Profil Pelanggan</th>
                <th className="py-3.5 px-4">Kontak</th>
                <th className="py-3.5 px-4">Alamat Terdaftar</th>
                <th className="py-3.5 px-4">Aktivitas Pemesanan</th>
                <th className="py-3.5 px-4">Total Pengeluaran</th>
                <th className="py-3.5 px-5 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    <Users className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                    <p className="font-medium text-slate-600">
                      {dataLoading?.users ? 'Memuat data pengguna...' : 'Tidak ada pengguna ditemukan'}
                    </p>
                    <p className="text-xs text-slate-400 mt-0.5">
                      {searchQuery ? 'Coba cari dengan kata kunci lain.' : 'Belum ada pengguna terdaftar di sistem.'}
                    </p>
                  </td>
                </tr>
              ) : (
                filteredUsers.map((u) => {
                  const userCompletedTickets = (ticketsList || []).filter(
                    (t) => (t.userId === u.id || t.userId === u.uid) && t.status === 'COMPLETED'
                  );
                  const totalOrders = (u.totalOrders != null && u.totalOrders > 0) 
                    ? u.totalOrders 
                    : userCompletedTickets.length;
                  const totalSpent = (u.totalSpent != null && u.totalSpent > 0) 
                    ? u.totalSpent 
                    : userCompletedTickets.reduce((sum, t) => sum + (t.finalBill?.totalAmount || 0), 0);
                  const avatarUrl = u.avatar || u.photoUrl || DEFAULT_AVATAR;

                  return (
                    <tr key={u.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="py-4 px-5">
                        <div className="flex items-center gap-3">
                          <img 
                            src={avatarUrl} 
                            alt={u.name || 'User'} 
                            onError={(e) => {
                              e.currentTarget.src = DEFAULT_AVATAR;
                            }}
                            className="w-10 h-10 rounded-xl object-cover ring-1 ring-slate-200" 
                          />
                          <div>
                            <p className="font-bold text-slate-900">{u.name || 'Pengguna Beres'}</p>
                            <p className="text-slate-400 text-[11px] font-mono">{u.id}</p>
                          </div>
                        </div>
                      </td>

                      <td className="py-4 px-4 text-slate-700">
                        <p className="font-medium">{u.phone || '-'}</p>
                        <p className="text-slate-400 text-[11px]">{u.email || '-'}</p>
                      </td>

                      <td className="py-4 px-4 text-slate-600 max-w-xs truncate">
                        <p className="flex items-center gap-1 text-[11px]">
                          <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                          <span className="truncate">{u.address || 'Alamat Belum Diatur'}</span>
                        </p>
                      </td>

                      <td className="py-4 px-4">
                        <span className="font-bold text-slate-900">{totalOrders}</span>
                        <span className="text-slate-500 text-[11px]"> order selesai</span>
                      </td>

                      <td className="py-4 px-4">
                        <p className="font-bold text-slate-900 font-mono">
                          Rp {(totalSpent || 0).toLocaleString('id-ID')}
                        </p>
                      </td>

                      <td className="py-4 px-5 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                            <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                            {u.status || 'Aktif'}
                          </span>
                          <button
                            onClick={() => {
                              if (window.confirm(`Hapus permanen data pengguna "${u.name}" (ID: ${u.id}) dari database?`)) {
                                deleteUser(u.id);
                              }
                            }}
                            className="p-1.5 rounded-lg bg-slate-50 hover:bg-rose-50 text-slate-400 hover:text-rose-600 border border-slate-200 hover:border-rose-200 transition-colors"
                            title="Hapus data pengguna dari database"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
