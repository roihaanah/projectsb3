import { useEffect, useState } from 'react';

// Status koneksi ke backend
const STATE = {
  LOADING: 'loading',
  OK: 'ok',
  ERROR: 'error',
};

export default function App() {
  const [state, setState] = useState(STATE.LOADING);
  const [detail, setDetail] = useState(null);

  async function cekHealth() {
    setState(STATE.LOADING);
    setDetail(null);
    try {
      const res = await fetch('/api/health');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setDetail(data);
      setState(data.status === 'OK' ? STATE.OK : STATE.ERROR);
    } catch (err) {
      setDetail({ message: err.message });
      setState(STATE.ERROR);
    }
  }

  useEffect(() => {
    cekHealth();
  }, []);

  const badge = {
    [STATE.LOADING]: { teks: 'Memeriksa...', warna: '#6b7280' },
    [STATE.OK]: { teks: 'OK', warna: '#16a34a' },
    [STATE.ERROR]: { teks: 'GAGAL', warna: '#dc2626' },
  }[state];

  return (
    <main
      style={{
        background: '#fff',
        padding: '2rem 2.5rem',
        borderRadius: 12,
        boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
        width: 'min(90vw, 420px)',
        textAlign: 'center',
      }}
    >
      <h1 style={{ margin: '0 0 0.25rem' }}>SiAbsen</h1>
      <p style={{ margin: '0 0 1.5rem', color: '#6b7280' }}>
        Aplikasi Manajemen Kelas
      </p>

      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '0.5rem',
          marginBottom: '1rem',
        }}
      >
        <span>Status Backend:</span>
        <strong
          style={{
            padding: '0.2rem 0.75rem',
            borderRadius: 999,
            background: badge.warna,
            color: '#fff',
            fontSize: '0.9rem',
          }}
        >
          {badge.teks}
        </strong>
      </div>

      {detail && (
        <pre
          style={{
            textAlign: 'left',
            background: '#f9fafb',
            border: '1px solid #e5e7eb',
            borderRadius: 8,
            padding: '0.75rem',
            fontSize: '0.8rem',
            overflowX: 'auto',
            margin: '0 0 1rem',
          }}
        >
          {JSON.stringify(detail, null, 2)}
        </pre>
      )}

      <button
        onClick={cekHealth}
        style={{
          cursor: 'pointer',
          border: 'none',
          background: '#2563eb',
          color: '#fff',
          padding: '0.6rem 1.2rem',
          borderRadius: 8,
          fontSize: '0.95rem',
        }}
      >
        Cek ulang
      </button>
    </main>
  );
}
