import React, { useState } from 'react';
import { Users, Search, ShoppingBag, MapPin, Calendar, CheckCircle2 } from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

export default function UserListPage() {
  const { usersList } = useAdminData();
  const [searchQuery, setSearchQuery] = useState('');

  const filteredUsers = usersList.filter(u => 
    u.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    u.phone.includes(searchQuery)
  );

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Daftar Pengguna (Pelanggan)</h2>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-700">
              Total {usersList.length} User
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
              {filteredUsers.map((u) => (
                <tr key={u.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="py-4 px-5">
                    <div className="flex items-center gap-3">
                      <img src={u.avatar} alt={u.name} className="w-10 h-10 rounded-xl object-cover ring-1 ring-slate-200" />
                      <div>
                        <p className="font-bold text-slate-900">{u.name}</p>
                        <p className="text-slate-400 text-[11px] font-mono">{u.id}</p>
                      </div>
                    </div>
                  </td>

                  <td className="py-4 px-4 text-slate-700">
                    <p className="font-medium">{u.phone}</p>
                    <p className="text-slate-400 text-[11px]">{u.email}</p>
                  </td>

                  <td className="py-4 px-4 text-slate-600 max-w-xs truncate">
                    <p className="flex items-center gap-1 text-[11px]">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="truncate">{u.address}</span>
                    </p>
                  </td>

                  <td className="py-4 px-4">
                    <span className="font-bold text-slate-900">{u.totalOrders}</span>
                    <span className="text-slate-500 text-[11px]"> order selesai</span>
                  </td>

                  <td className="py-4 px-4">
                    <p className="font-bold text-slate-900 font-mono">
                      Rp {u.totalSpent.toLocaleString('id-ID')}
                    </p>
                  </td>

                  <td className="py-4 px-5 text-right">
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                      <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                      {u.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
