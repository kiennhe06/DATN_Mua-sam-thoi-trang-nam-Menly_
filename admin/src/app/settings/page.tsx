'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { Header } from '../../components/Header';
import { checkServerHealth } from '../../lib/api';
import {
  Server, Database, RefreshCw, CheckCircle2,
  Wifi, WifiOff, Zap, Activity, Shield, Globe,
  Cpu, HardDrive, Clock, AlertTriangle, Terminal,
  ChevronRight, Radio
} from 'lucide-react';

interface PingEntry { time: number; ms: number; ok: boolean }
interface ServiceStatus { name: string; url: string; status: 'online' | 'offline' | 'checking' | 'unknown'; latency: number | null; icon: React.ElementType; color: string }

function Sparkline({ data, color = '#b8824a' }: { data: number[]; color?: string }) {
  if (data.length < 2) return <div className="w-full h-10 flex items-center justify-center text-ink-muted text-[10px]">Đang thu thập...</div>;
  const max = Math.max(...data, 1);
  const w = 200; const h = 40;
  const pts = data.map((v, i) => `${(i / (data.length - 1)) * w},${h - (v / max) * h}`).join(' ');
  return (
    <svg viewBox={`0 0 ${w} ${h}`} className="w-full h-10" preserveAspectRatio="none">
      <defs>
        <linearGradient id="sg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.3" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <polyline points={pts} fill="none" stroke={color} strokeWidth="1.5" strokeLinejoin="round" />
      <polygon points={`0,${h} ${pts} ${w},${h}`} fill="url(#sg)" />
    </svg>
  );
}

function PulseDot({ online }: { online: boolean | null }) {
  if (online === null) return <span className="w-2.5 h-2.5 rounded-full bg-line-strong inline-block" />;
  return (
    <span className="relative inline-flex w-2.5 h-2.5">
      <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-60 ${online ? 'bg-ok' : 'bg-danger'}`} />
      <span className={`relative inline-flex rounded-full w-2.5 h-2.5 ${online ? 'bg-ok' : 'bg-danger'}`} />
    </span>
  );
}

export default function SettingsPage() {
  const [apiUrl, setApiUrl] = useState('http://localhost:5000');
  const [hasAdminToken, setHasAdminToken] = useState(false);
  const [saved, setSaved] = useState(false);
  const [pings, setPings] = useState<PingEntry[]>([]);
  const [uptime, setUptime] = useState(0);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [lastCheck, setLastCheck] = useState<Date | null>(null);
  const [services, setServices] = useState<ServiceStatus[]>([
    { name: 'Backend API', url: '/api/v1/health', status: 'checking', latency: null, icon: Server, color: 'amber' },
    { name: 'Supabase DB', url: 'https://lihnuaymkrwmgdspnkux.supabase.co', status: 'checking', latency: null, icon: Database, color: 'blue' },
    { name: 'VNPay Gateway', url: 'https://sandbox.vnpayment.vn', status: 'checking', latency: null, icon: Globe, color: 'green' },
  ]);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const startRef = useRef<number>(0);

  const checkAll = useCallback(async () => {
    const t0 = Date.now();
    const ok = await checkServerHealth();
    const ms = Date.now() - t0;
    setLastCheck(new Date());
    setPings(prev => [...prev.slice(-19), { time: Date.now(), ms, ok }]);
    setUptime(Math.floor((Date.now() - startRef.current) / 1000));

    setServices(prev => prev.map((s, i) => {
      if (i === 0) return { ...s, status: ok ? 'online' : 'offline', latency: ms };
      // External services (Supabase, VNPay) cannot be probed directly from the
      // browser (CORS), so their status is not monitored here.
      return { ...s, status: 'unknown', latency: null };
    }));
  }, []);

  useEffect(() => {
    startRef.current = Date.now();
    if (typeof window !== 'undefined') {
      setApiUrl(localStorage.getItem('menshop_api_url') || 'http://localhost:5000');
      setHasAdminToken(Boolean(localStorage.getItem('menshop_admin_token')));
    }
    checkAll();
  }, [checkAll]);

  useEffect(() => {
    if (autoRefresh) {
      intervalRef.current = setInterval(checkAll, 10000);
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current);
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [autoRefresh, checkAll]);

  function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (typeof window !== 'undefined') {
      localStorage.setItem('menshop_api_url', apiUrl);
    }
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
    checkAll();
  }

  const isOnline = pings.length > 0 ? pings[pings.length - 1].ok : null;
  const avgMs = pings.length > 0 ? Math.round(pings.reduce((a, b) => a + b.ms, 0) / pings.length) : null;
  const successRate = pings.length > 0 ? Math.round((pings.filter(p => p.ok).length / pings.length) * 100) : null;
  const latencyData = pings.map(p => p.ms);

  const colorMap: Record<string, string> = {
    amber: 'text-camel-dark bg-camel-tint border-camel/25',
    blue: 'text-blue-700 bg-blue-50 border-blue-200',
    green: 'text-ok bg-ok-bg border-ok-line',
  };

  const statusBadge = (s: ServiceStatus) =>
    s.status === 'online'
      ? 'bg-ok-bg text-ok border-ok-line'
      : s.status === 'offline'
        ? 'bg-danger-bg text-danger border-danger-line'
        : 'bg-tint-strong text-ink-muted border-line';

  const statusLabel = (s: ServiceStatus) => {
    switch (s.status) {
      case 'online':
        return '● Online';
      case 'offline':
        return '● Offline';
      case 'unknown':
        return 'Không giám sát';
      default:
        return '...';
    }
  };

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <Header
        title="Giám sát Hệ thống & Cấu hình"
        subtitle="Dashboard thời gian thực — theo dõi trạng thái Backend, Latency, Uptime và kết nối dịch vụ"
        onRefresh={checkAll}
      />

      <div className="flex-1 space-y-6 overflow-auto p-4 sm:p-6">

        {/* Saved Alert */}
        {saved && (
          <div className="p-3.5 rounded-xl bg-ok-bg border border-ok-line text-ok text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4" /><span>Đã lưu cấu hình thành công!</span>
          </div>
        )}

        {/* TOP KPI CARDS */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            {
              label: 'Trạng thái',
              value: isOnline === null ? 'Checking...' : isOnline ? 'ONLINE' : 'OFFLINE',
              sub: lastCheck ? `${lastCheck.toLocaleTimeString('vi-VN')}` : '—',
              icon: isOnline ? Wifi : WifiOff,
              color: isOnline === null ? 'text-ink-muted' : isOnline ? 'text-ok' : 'text-danger',
              bg: isOnline === null ? 'bg-tint' : isOnline ? 'bg-ok-bg border-ok-line' : 'bg-danger-bg border-danger-line',
            },
            {
              label: 'Latency TB',
              value: avgMs !== null ? `${avgMs}ms` : '—',
              sub: avgMs !== null ? (avgMs < 100 ? 'Xuất sắc' : avgMs < 300 ? 'Tốt' : 'Chậm') : 'Chưa đo',
              icon: Zap,
              color: avgMs === null ? 'text-ink-muted' : avgMs < 100 ? 'text-ok' : avgMs < 300 ? 'text-camel-dark' : 'text-danger',
              bg: 'bg-camel-tint border-camel/20',
            },
            {
              label: 'Uptime phiên',
              value: uptime > 0 ? `${Math.floor(uptime / 60)}m ${uptime % 60}s` : '—',
              sub: 'Kể từ khi mở trang',
              icon: Clock,
              color: 'text-blue-700',
              bg: 'bg-blue-50 border-blue-200',
            },
            {
              label: 'Tỉ lệ thành công',
              value: successRate !== null ? `${successRate}%` : '—',
              sub: `${pings.filter(p => p.ok).length}/${pings.length} requests`,
              icon: Activity,
              color: successRate === null ? 'text-ink-muted' : successRate === 100 ? 'text-ok' : 'text-camel-dark',
              bg: 'bg-tint border-line',
            },
          ].map((card) => (
            <div key={card.label} className={`rounded-2xl p-4 border ${card.bg} space-y-2`}>
              <div className="flex items-center justify-between">
                <span className="text-[11px] text-ink-muted font-semibold uppercase tracking-wider">{card.label}</span>
                <card.icon className={`w-4 h-4 ${card.color}`} />
              </div>
              <div className={`text-xl font-black font-mono ${card.color}`}>{card.value}</div>
              <div className="text-[11px] text-ink-muted">{card.sub}</div>
            </div>
          ))}
        </div>

        {/* LATENCY CHART + SERVICES */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

          {/* Latency Sparkline */}
          <div className="bg-panel border border-line rounded-2xl p-5 space-y-4 shadow-panel">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Activity className="w-4 h-4 text-camel-dark" />
                <h3 className="font-bold text-sm text-ink">Biểu đồ Latency (20 lần ping gần nhất)</h3>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setAutoRefresh(v => !v)}
                  className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[11px] font-semibold border transition-all cursor-pointer ${autoRefresh ? 'bg-ok-bg border-ok-line text-ok' : 'bg-tint border-line-strong text-ink-muted'}`}
                >
                  <Radio className={`w-3 h-3 ${autoRefresh ? 'animate-pulse' : ''}`} />
                  {autoRefresh ? 'Live' : 'Tạm dừng'}
                </button>
                <button onClick={checkAll} className="p-1.5 rounded-lg bg-tint hover:bg-tint-strong text-ink-muted hover:text-ink transition-colors cursor-pointer">
                  <RefreshCw className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            <Sparkline data={latencyData} color="#b8824a" />
            <div className="flex justify-between text-[10px] text-ink-muted font-mono">
              {pings.length > 0
                ? <><span>Min: {Math.min(...latencyData)}ms</span><span>Avg: {avgMs}ms</span><span>Max: {Math.max(...latencyData)}ms</span></>
                : <span className="text-center w-full">Đang ping server...</span>
              }
            </div>
          </div>

          {/* Services Status */}
          <div className="bg-panel border border-line rounded-2xl p-5 space-y-4 shadow-panel">
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4 text-camel-dark" />
              <h3 className="font-bold text-sm text-ink">Dịch vụ kết nối</h3>
            </div>
            <div className="space-y-3">
              {services.map((svc) => (
                <div key={svc.name} className="flex items-center justify-between p-3 rounded-xl bg-tint border border-line">
                  <div className="flex items-center gap-2.5">
                    <div className={`p-1.5 rounded-lg border ${colorMap[svc.color]}`}>
                      <svc.icon className={`w-3.5 h-3.5`} />
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-ink">{svc.name}</p>
                      <p className="text-[10px] text-ink-muted font-mono">{svc.url}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {svc.latency !== null && (
                      <span className="text-[10px] font-mono text-ink-muted">{svc.latency}ms</span>
                    )}
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${statusBadge(svc)}`}>
                      {statusLabel(svc)}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* CONFIG FORM */}
        <form onSubmit={handleSave} className="bg-panel border border-line rounded-2xl p-5 space-y-4 shadow-panel">
          <div className="flex items-center gap-2 mb-1">
            <Terminal className="w-4 h-4 text-camel-dark" />
            <h3 className="font-bold text-sm text-ink">Tham số Kết nối</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div>
              <label className="text-ink-muted font-semibold block mb-1.5">Backend API URL</label>
              <div className="flex gap-2">
                <input
                  type="text" value={apiUrl} onChange={(e) => setApiUrl(e.target.value)}
                  className="flex-1 px-3 py-2 bg-panel border border-line rounded-xl text-ink font-mono text-xs focus:outline-none focus:border-camel transition-colors shadow-panel"
                />
                <button type="button" onClick={checkAll}
                  className="px-3 py-2 bg-tint hover:bg-tint-strong rounded-xl text-ink-mid transition-colors cursor-pointer flex items-center gap-1">
                  <Zap className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            <div>
              <label className="text-ink-muted font-semibold block mb-1.5">Phiên đăng nhập quản trị</label>
              <input
                type="text" value={hasAdminToken ? 'Đã có access token từ phiên đăng nhập' : 'Chưa đăng nhập'} readOnly
                className="w-full px-3 py-2 bg-panel border border-line rounded-lg text-ink-muted text-xs cursor-not-allowed shadow-panel"
              />
            </div>
          </div>
          <div className="flex items-center justify-between pt-1">
            <p className="text-[11px] text-ink-muted flex items-center gap-1">
              <AlertTriangle className="w-3 h-3" /> Cấu hình lưu trong LocalStorage trình duyệt
            </p>
            <button type="submit"
              className="px-5 py-2 rounded-xl font-bold bg-camel text-ink hover:bg-camel-hover transition-colors text-xs cursor-pointer shadow-lg shadow-camel/20 flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5" /> Lưu & Kiểm tra
            </button>
          </div>
        </form>

        {/* SYSTEM TOPOLOGY */}
        <div className="bg-panel border border-line rounded-2xl p-5 space-y-4 shadow-panel">
          <div className="flex items-center gap-2">
            <Cpu className="w-4 h-4 text-camel-dark" />
            <h3 className="font-bold text-sm text-ink">Kiến trúc Hệ thống MenShop</h3>
          </div>
          <div className="flex items-center justify-center gap-2 flex-wrap py-2">
            {[
              { label: 'Flutter App', sub: 'iOS / Android / Web', icon: '📱', color: 'border-blue-200 bg-blue-50' },
              { label: '→', sub: '', icon: '', color: 'border-none bg-none' },
              { label: 'Next.js Admin', sub: 'Port 3000', icon: '🖥️', color: 'border-purple-200 bg-purple-50' },
              { label: '→', sub: '', icon: '', color: 'border-none bg-none' },
              { label: 'Express API', sub: 'Port 5000', icon: '⚡', color: `border-camel/40 bg-camel-tint ${isOnline ? 'shadow-camel/20 shadow-lg' : ''}` },
              { label: '→', sub: '', icon: '', color: 'border-none bg-none' },
              { label: 'Supabase', sub: 'PostgreSQL + Auth', icon: '🗄️', color: 'border-ok-line bg-ok-bg' },
            ].map((node, i) =>
              node.label === '→'
                ? <ChevronRight key={i} className="w-4 h-4 text-ink-muted" />
                : (
                  <div key={i} className={`flex flex-col items-center p-3 rounded-xl border ${node.color} min-w-[90px]`}>
                    <span className="text-xl mb-1">{node.icon}</span>
                    <span className="text-xs font-bold text-ink">{node.label}</span>
                    <span className="text-[10px] text-ink-muted">{node.sub}</span>
                    {node.label === 'Express API' && (
                      <div className="mt-1.5 flex items-center gap-1">
                        <PulseDot online={isOnline} />
                        <span className={`text-[9px] font-bold ${isOnline ? 'text-ok' : 'text-danger'}`}>
                          {isOnline === null ? '...' : isOnline ? 'Live' : 'Down'}
                        </span>
                      </div>
                    )}
                  </div>
                )
            )}
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs pt-1">
            {[
              { icon: HardDrive, label: 'VNPay Sandbox', desc: 'HMAC-SHA512' },
              { icon: Shield, label: 'RLS Supabase', desc: 'Row Level Security' },
              { icon: Activity, label: 'Dữ liệu sản phẩm', desc: 'Nguồn từ Supabase' },
              { icon: Zap, label: 'Clean Arch', desc: 'MVVM Pattern' },
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-2 p-2.5 rounded-xl bg-tint border border-line">
                <item.icon className="w-3.5 h-3.5 text-camel-dark flex-shrink-0" />
                <div>
                  <p className="font-semibold text-ink text-[11px]">{item.label}</p>
                  <p className="text-ink-muted text-[10px]">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}
