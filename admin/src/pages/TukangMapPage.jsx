import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { 
  MapPin, 
  Search, 
  Wrench, 
  Navigation, 
  Phone, 
  ShieldAlert, 
  Star,
  CheckCircle2,
  Clock
} from 'lucide-react';
import { useAdminData } from '../context/AdminDataContext';

// Custom SVG Markers for Leaflet
function createCustomMarkerIcon(status, isSuspended) {
  let bgColor = '#3B82F6'; // Default Blue
  if (isSuspended) bgColor = '#EF4444'; // Red
  else if (status === 'Menuju Lokasi') bgColor = '#F59E0B'; // Amber
  else if (status === 'Sedang Bekerja') bgColor = '#10B981'; // Emerald
  else if (status.includes('Menunggu') || !status.includes('Online')) bgColor = '#94A3B8'; // Slate

  const svgIcon = `
    <div style="
      background-color: ${bgColor};
      width: 36px;
      height: 36px;
      border-radius: 50%;
      border: 3px solid white;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    ">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path>
      </svg>
    </div>
  `;

  return L.divIcon({
    html: svgIcon,
    className: 'custom-leaflet-marker',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -20]
  });
}

// Helper to center and zoom map dynamically
function MapFlyTo({ targetCoords }) {
  const map = useMap();
  useEffect(() => {
    if (targetCoords) {
      map.flyTo(targetCoords, 15, { duration: 1.2 });
    }
  }, [targetCoords, map]);
  return null;
}

export default function TukangMapPage() {
  const { tukangList } = useAdminData();
  const [selectedTukang, setSelectedTukang] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL'); // 'ALL' | 'ACTIVE' | 'ON_THE_WAY' | 'SUSPENDED'

  const filteredTukang = tukangList.filter(t => {
    const matchesSearch = 
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.services.some(s => s.toLowerCase().includes(searchQuery.toLowerCase()));

    if (!matchesSearch) return false;
    if (statusFilter === 'ACTIVE') return t.isOnline && !t.isSuspended;
    if (statusFilter === 'ON_THE_WAY') return t.statusText === 'Menuju Lokasi';
    if (statusFilter === 'SUSPENDED') return t.isSuspended;
    return true;
  });

  const defaultCenter = [-6.2088, 106.8456]; // Jakarta Pusat

  return (
    <div className="space-y-4 max-w-7xl mx-auto">
      {/* Top Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-slate-900 tracking-tight">Lacak GPS Mitra Tukang</h2>
            <span className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-semibold">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              Live Radar
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Pantau sebaran koordinat dan status pergerakan fisik seluruh mitra di peta OpenStreetMap.
          </p>
        </div>

        {/* Legend */}
        <div className="flex flex-wrap items-center gap-3 bg-white px-4 py-2 rounded-xl border border-slate-200 text-xs text-slate-600 shadow-xs">
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-blue-500" /> Online
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-amber-500" /> Menuju Lokasi
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" /> Bekerja
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-rose-500" /> Suspend
          </span>
        </div>
      </div>

      {/* Main Map Container + Floating Sidebar */}
      <div className="relative h-[650px] rounded-3xl overflow-hidden border border-slate-200 shadow-lg bg-slate-100">
        <MapContainer
          center={defaultCenter}
          zoom={12}
          scrollWheelZoom={true}
          className="h-full w-full z-0"
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {selectedTukang?.currentLocation && (
            <MapFlyTo targetCoords={[selectedTukang.currentLocation.lat, selectedTukang.currentLocation.lng]} />
          )}

          {tukangList.map(t => {
            if (!t.currentLocation) return null;
            const markerIcon = createCustomMarkerIcon(t.statusText, t.isSuspended);

            return (
              <Marker
                key={t.id}
                position={[t.currentLocation.lat, t.currentLocation.lng]}
                icon={markerIcon}
                eventHandlers={{
                  click: () => setSelectedTukang(t)
                }}
              >
                <Popup className="custom-leaflet-popup">
                  <div className="p-1 space-y-2 min-w-[200px]">
                    <div className="flex items-center gap-2">
                      <img src={t.avatar} alt={t.name} className="w-8 h-8 rounded-lg object-cover" />
                      <div>
                        <p className="font-bold text-slate-900 text-xs">{t.name}</p>
                        <p className="text-[10px] text-slate-500">⭐ {t.rating} ({t.totalJobsDone} order)</p>
                      </div>
                    </div>
                    <div className="text-[11px] text-slate-600 bg-slate-50 p-2 rounded-lg border border-slate-100">
                      <p className="font-semibold text-slate-800">{t.statusText}</p>
                      <p className="text-[10px] text-slate-500 mt-0.5">{t.currentLocation.address}</p>
                    </div>
                  </div>
                </Popup>
              </Marker>
            );
          })}
        </MapContainer>

        {/* Floating Tukang Directory Drawer on Left Side */}
        <div className="absolute top-4 left-4 z-10 w-80 max-h-[610px] bg-white/95 backdrop-blur-md rounded-2xl shadow-xl border border-slate-200/80 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-slate-100 space-y-3">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Cari tukang atau keahlian..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-8.5 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>

            {/* Quick Status Chips */}
            <div className="flex items-center gap-1 overflow-x-auto text-[10px] font-bold">
              {['ALL', 'ACTIVE', 'ON_THE_WAY', 'SUSPENDED'].map(tab => (
                <button
                  key={tab}
                  onClick={() => setStatusFilter(tab)}
                  className={`px-2.5 py-1 rounded-md transition-colors ${
                    statusFilter === tab
                      ? 'bg-slate-900 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {tab === 'ALL' ? 'Semua' : tab === 'ACTIVE' ? 'Aktif' : tab === 'ON_THE_WAY' ? 'Jalan' : 'Suspend'}
                </button>
              ))}
            </div>
          </div>

          <div className="flex-1 overflow-y-auto divide-y divide-slate-100 p-2 space-y-1">
            {filteredTukang.map(t => {
              const isSelected = selectedTukang?.id === t.id;
              return (
                <button
                  key={t.id}
                  onClick={() => setSelectedTukang(t)}
                  className={`w-full text-left p-3 rounded-xl transition-all flex items-start gap-3 ${
                    isSelected 
                      ? 'bg-blue-50/80 border border-blue-200 shadow-xs' 
                      : 'hover:bg-slate-50 border border-transparent'
                  }`}
                >
                  <img src={t.avatar} alt={t.name} className="w-9 h-9 rounded-xl object-cover shrink-0 ring-1 ring-slate-200" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <p className="text-xs font-bold text-slate-900 truncate">{t.name}</p>
                      <span className={`text-[9px] font-bold px-1.5 py-0.2 rounded ${
                        t.isSuspended ? 'bg-rose-100 text-rose-800' :
                        t.statusText === 'Menuju Lokasi' ? 'bg-amber-100 text-amber-800' :
                        t.isOnline ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-600'
                      }`}>
                        {t.isSuspended ? 'Suspend' : t.statusText}
                      </span>
                    </div>

                    <p className="text-[10px] text-slate-500 truncate mt-0.5">
                      📍 {t.currentLocation?.address || 'Lokasi tidak aktif'}
                    </p>

                    <div className="flex items-center gap-2 mt-1.5 text-[10px] text-slate-400">
                      <span>⭐ {t.rating}</span>
                      <span>•</span>
                      <span>Update: {t.currentLocation?.updatedAt}</span>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
