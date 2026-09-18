// Realistic mock data for Beres Ecosystem
// Strictly tailored to Indonesian context, 10 categories, DOKU & payout channels

export const initialTukangList = [
  {
    id: "TKG-001",
    name: "Ahmad Subarjo",
    email: "ahmad.subarjo@gmail.com",
    phone: "0813-8891-2341",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80",
    birthDate: "1988-06-14",
    age: 38,
    services: ["ac", "elektronik", "plumbing"],
    payoutAccounts: [
      { type: "bank", provider: "BCA", accountNumber: "2102198765", accountName: "Ahmad Subarjo" },
      { type: "ewallet", provider: "DANA", accountNumber: "081388912341", accountName: "Ahmad Subarjo" }
    ],
    ktpUrl: "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800&auto=format&fit=crop&q=80",
    ktpNik: "3276011406880002",
    verificationStatus: "verified", // pending_verification | verified | rejected
    rejectionReason: null,
    isSuspended: false,
    suspendedUntil: null,
    suspendReason: null,
    walletBalance: 875000,
    rating: 4.9,
    reviewCount: 42,
    totalJobsDone: 56,
    isOnline: true,
    statusText: "Menuju Lokasi",
    currentLocation: {
      lat: -6.2297,
      lng: 106.8295,
      address: "Jl. HR Rasuna Said, Kuningan, Jakarta Selatan",
      updatedAt: "Baru saja"
    },
    currentTicketId: "TCK-801",
    createdAt: "2026-08-10"
  },
  {
    id: "TKG-002",
    name: "Bambang Pamungkas",
    email: "bambang.las@yahoo.com",
    phone: "0812-9012-7788",
    avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80",
    birthDate: "1984-11-20",
    age: 41,
    services: ["las", "besi_baja", "bangunan"],
    payoutAccounts: [
      { type: "bank", provider: "MANDIRI", accountNumber: "1570008892112", accountName: "Bambang Pamungkas" }
    ],
    ktpUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80",
    ktpNik: "3171052011840003",
    verificationStatus: "pending_verification",
    rejectionReason: null,
    isSuspended: false,
    suspendedUntil: null,
    suspendReason: null,
    walletBalance: 0,
    rating: 5.0,
    reviewCount: 0,
    totalJobsDone: 0,
    isOnline: false,
    statusText: "Menunggu Verifikasi KTP",
    currentLocation: {
      lat: -6.1754,
      lng: 106.8272,
      address: "Jl. Gambir No. 15, Jakarta Pusat",
      updatedAt: "2 jam lalu"
    },
    createdAt: "2026-09-17"
  },
  {
    id: "TKG-003",
    name: "Hendra Wijaya",
    email: "hendra.cleaning@gmail.com",
    phone: "0857-1122-3344",
    avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80",
    birthDate: "1993-02-18",
    age: 33,
    services: ["cleaning", "pengrajin_kayu"],
    payoutAccounts: [
      { type: "bank", provider: "BRI", accountNumber: "034101000998501", accountName: "Hendra Wijaya" },
      { type: "ewallet", provider: "GOPAY", accountNumber: "085711223344", accountName: "Hendra Wijaya" }
    ],
    ktpUrl: "https://images.unsplash.com/photo-1544717305-2782549b5136?w=800&auto=format&fit=crop&q=80",
    ktpNik: "3275021802930007",
    verificationStatus: "verified",
    rejectionReason: null,
    isSuspended: true,
    suspendedUntil: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000 + 14 * 60 * 60 * 1000).toISOString(),
    suspendReason: "Membatalkan pesanan secara sepihak dan meminta tarif di luar tagihan aplikasi",
    walletBalance: 320000,
    rating: 3.6,
    reviewCount: 15,
    totalJobsDone: 18,
    isOnline: false,
    statusText: "Suspended (3 Hari)",
    currentLocation: {
      lat: -6.2615,
      lng: 106.8106,
      address: "Kemang Raya, Mampang, Jakarta Selatan",
      updatedAt: "Kemarin"
    },
    createdAt: "2026-07-25"
  },
  {
    id: "TKG-004",
    name: "Rizki Pratama",
    email: "rizki.motor@gmail.com",
    phone: "0878-9988-1234",
    avatar: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80",
    birthDate: "1995-09-09",
    age: 30,
    services: ["bengkel_motor", "bengkel_mobil"],
    payoutAccounts: [
      { type: "bank", provider: "BNI", accountNumber: "0891234567", accountName: "Rizki Pratama" },
      { type: "ewallet", provider: "OVO", accountNumber: "087899881234", accountName: "Rizki Pratama" }
    ],
    ktpUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80",
    ktpNik: "3174090909950005",
    verificationStatus: "verified",
    rejectionReason: null,
    isSuspended: false,
    suspendedUntil: null,
    suspendReason: null,
    walletBalance: 1250000,
    rating: 4.8,
    reviewCount: 31,
    totalJobsDone: 39,
    isOnline: true,
    statusText: "Online / Siap Kerja",
    currentLocation: {
      lat: -6.1944,
      lng: 106.8229,
      address: "Bundaran HI, Menteng, Jakarta Pusat",
      updatedAt: "1 menit lalu"
    },
    createdAt: "2026-08-01"
  },
  {
    id: "TKG-005",
    name: "Dedi Suryadi",
    email: "dedi.plumbing@gmail.com",
    phone: "0812-4455-6677",
    avatar: "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=150&auto=format&fit=crop&q=80",
    birthDate: "1986-04-03",
    age: 40,
    services: ["plumbing", "bangunan"],
    payoutAccounts: [
      { type: "bank", provider: "BCA", accountNumber: "5220918273", accountName: "Dedi Suryadi" }
    ],
    ktpUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80",
    ktpNik: "3271010304860001",
    verificationStatus: "pending_verification",
    rejectionReason: null,
    isSuspended: false,
    suspendedUntil: null,
    suspendReason: null,
    walletBalance: 0,
    rating: 5.0,
    reviewCount: 0,
    totalJobsDone: 0,
    isOnline: false,
    statusText: "Menunggu Verifikasi KTP",
    currentLocation: {
      lat: -6.2412,
      lng: 106.7995,
      address: "Blok M, Kebayoran Baru, Jakarta Selatan",
      updatedAt: "3 jam lalu"
    },
    createdAt: "2026-09-18"
  }
];

export const initialUsersList = [
  {
    id: "USR-001",
    name: "Siti Rahmawati",
    email: "siti.rahmawati@gmail.com",
    phone: "0812-3344-5566",
    avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80",
    totalOrders: 8,
    totalSpent: 1250000,
    address: "Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan",
    status: "Aktif",
    joinedDate: "2026-06-12"
  },
  {
    id: "USR-002",
    name: "Dimas Anggara",
    email: "dimas.anggara@gmail.com",
    phone: "0813-7766-5544",
    avatar: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80",
    totalOrders: 4,
    totalSpent: 620000,
    address: "Apartemen Sudirman Tower A-12, Jakarta Pusat",
    status: "Aktif",
    joinedDate: "2026-07-01"
  },
  {
    id: "USR-003",
    name: "dr. Kevin Sanjaya",
    email: "kevin.sanjaya@rs.co.id",
    phone: "0811-9876-5432",
    avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80",
    totalOrders: 14,
    totalSpent: 3400000,
    address: "Jl. Danau Sunter Utara Blok B No. 5, Jakarta Utara",
    status: "Aktif",
    joinedDate: "2026-05-19"
  },
  {
    id: "USR-004",
    name: "Maya Indah",
    email: "maya.indah@yahoo.com",
    phone: "0856-4433-2211",
    avatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80",
    totalOrders: 2,
    totalSpent: 175000,
    address: "Jl. Tebet Barat Dalam VII No. 9, Jakarta Selatan",
    status: "Aktif",
    joinedDate: "2026-09-02"
  }
];

export const initialTicketsList = [
  {
    id: "TCK-801",
    userId: "USR-001",
    userName: "Siti Rahmawati",
    userPhone: "0812-3344-5566",
    category: "ac",
    categoryLabel: "Servis AC",
    title: "AC Daikin 1 PK Kamar Tidur Bocor Menetes",
    description: "Air menetes deras dari indoor unit sejak tadi malam dan angin AC kurang dingin. Perlu dicek pipa pembuangan dan dicuci bersih.",
    address: "Jl. Wijaya II No. 18, Kebayoran Baru, Jakarta Selatan",
    location: { lat: -6.2382, lng: 106.8123 },
    status: "ON_THE_WAY",
    statusLabel: "Tukang Menuju Lokasi",
    selectedTukangId: "TKG-001",
    selectedTukangName: "Ahmad Subarjo",
    bids: [
      {
        tukangId: "TKG-001",
        tukangName: "Ahmad Subarjo",
        estimatedPrice: 150000,
        note: "Siap datang langsung bawa steam cuci AC dan alat cek tekanan freon."
      }
    ],
    finalBill: {
      items: [
        { title: "Jasa Cuci Servis AC 1 PK", amount: 75000 },
        { title: "Perbaikan Selang Pembuangan Tersumbat", amount: 50000 }
      ],
      totalAmount: 125000,
      approvedByUser: true
    },
    issuePhotos: [
      "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600&auto=format&fit=crop&q=80"
    ],
    beforePhotos: [
      "https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&auto=format&fit=crop&q=80"
    ],
    afterPhotos: [],
    paymentMethod: "doku",
    paymentStatus: "unpaid",
    createdAt: "2026-09-18 07:30 WIB"
  },
  {
    id: "TCK-802",
    userId: "USR-002",
    userName: "Dimas Anggara",
    userPhone: "0813-7766-5544",
    category: "plumbing",
    categoryLabel: "Plumbing",
    title: "Pipa Saluran Cuci Piring Mampet Total",
    description: "Air tidak bisa mengalir sama sekali di sink dapur. Sudah dicoba tuang air panas tetap buntu.",
    address: "Apartemen Sudirman Tower A-12, Jakarta Pusat",
    location: { lat: -6.2155, lng: 106.8198 },
    status: "OPEN",
    statusLabel: "Mencari Penawaran",
    selectedTukangId: null,
    selectedTukangName: null,
    bids: [
      {
        tukangId: "TKG-001",
        tukangName: "Ahmad Subarjo",
        estimatedPrice: 175000,
        note: "Akan kami tembak dengan kompresor pipa mampet spiral."
      }
    ],
    issuePhotos: [
      "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600&auto=format&fit=crop&q=80"
    ],
    beforePhotos: [],
    afterPhotos: [],
    paymentMethod: null,
    paymentStatus: "unpaid",
    createdAt: "2026-09-18 08:15 WIB"
  },
  {
    id: "TCK-799",
    userId: "USR-003",
    userName: "dr. Kevin Sanjaya",
    userPhone: "0811-9876-5432",
    category: "las",
    categoryLabel: "Teralis & Las",
    title: "Perbaikan Engsel Gerbang Dorong Pagar Patah",
    description: "Roda gerbang lepas dari rel dan engsel utama las lepas.",
    address: "Jl. Danau Sunter Utara Blok B No. 5, Jakarta Utara",
    location: { lat: -6.1382, lng: 106.8623 },
    status: "COMPLETED",
    statusLabel: "Selesai & Lunas",
    selectedTukangId: "TKG-002",
    selectedTukangName: "Bambang Pamungkas",
    bids: [],
    finalBill: {
      items: [
        { title: "Pengelasan Ulang Engsel Gerbang", amount: 200000 },
        { title: "Penggantian 2 Roda Rel Baja 3 Inci", amount: 150000 }
      ],
      totalAmount: 350000,
      approvedByUser: true
    },
    issuePhotos: [
      "https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?w=600&auto=format&fit=crop&q=80"
    ],
    beforePhotos: [
      "https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?w=600&auto=format&fit=crop&q=80"
    ],
    afterPhotos: [
      "https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=600&auto=format&fit=crop&q=80"
    ],
    paymentMethod: "doku",
    paymentStatus: "paid",
    rating: {
      stars: 5,
      review: "Pak Bambang kerjanya rapi sekali dan las sangat kokoh. Sangat puas!"
    },
    createdAt: "2026-09-17 14:00 WIB"
  }
];

export const initialWithdrawalsList = [
  {
    id: "WD-901",
    tukangId: "TKG-001",
    tukangName: "Ahmad Subarjo",
    amount: 500000,
    payoutTarget: {
      provider: "BCA",
      accountNumber: "2102198765",
      accountName: "Ahmad Subarjo"
    },
    status: "pending", // pending | approved | rejected
    requestedAt: "2026-09-18 06:45 WIB"
  },
  {
    id: "WD-899",
    tukangId: "TKG-004",
    tukangName: "Rizki Pratama",
    amount: 750000,
    payoutTarget: {
      provider: "BNI",
      accountNumber: "0891234567",
      accountName: "Rizki Pratama"
    },
    status: "approved",
    requestedAt: "2026-09-17 10:20 WIB",
    processedAt: "2026-09-17 11:05 WIB",
    adminNote: "Transfer sukses via Virtual Payout BNI Ref #TRX88291"
  }
];
