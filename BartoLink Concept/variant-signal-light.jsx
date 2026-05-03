// Variant C — "Signal Light"
// Aufbau wie Signal (Cockpit, dichte Listen, Live-Hero), aber:
// - Hellblauer pastellfarbener Hintergrund wie die aktuelle App
// - SF Pro / iOS System-Font (rund, freundlich)
// - Light Mode
// - Mono nur sehr sparsam für reine Datenlabel

const SL = {
  // Pastel-Blau Verlauf (wie Theme.swift backgroundGradient.light)
  bg1:    'rgb(217, 237, 255)',   // sehr hell oben (0.85, 0.93, 1.00)
  bg2:    'rgb(184, 217, 250)',   // tiefer unten (0.72, 0.85, 0.98)
  card:   'rgba(255,255,255,0.78)',
  cardBd: 'rgba(15,32,60,0.08)',
  hair:   'rgba(15,32,60,0.10)',
  ink:    '#0F1F33',
  ink2:   '#4A5A72',
  ink3:   '#8593A8',
  // Akzente — gleiche Sättigung/Lightness, nur Hue variiert (oklch)
  blue:   'oklch(0.62 0.15 245)',
  amber:  'oklch(0.68 0.15 65)',
  green:  'oklch(0.62 0.14 150)',
  violet: 'oklch(0.62 0.14 295)',
  red:    'oklch(0.62 0.18 25)',
  // Type — System Font (was iOS rendert)
  sys:    '-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Helvetica Neue", system-ui, sans-serif',
  mono:   'ui-monospace, "SF Mono", Menlo, monospace',
};

function SlBg() {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: `linear-gradient(180deg, ${SL.bg1} 0%, ${SL.bg2} 100%)`,
    }} />
  );
}

function SlCard({ children, style = {}, padded = true, accent }) {
  return (
    <div style={{
      background: SL.card,
      backdropFilter: 'blur(18px) saturate(160%)',
      WebkitBackdropFilter: 'blur(18px) saturate(160%)',
      border: `1px solid ${SL.cardBd}`,
      borderRadius: 18,
      padding: padded ? 16 : 0,
      position: 'relative',
      boxShadow: '0 1px 0 rgba(255,255,255,0.7) inset, 0 6px 18px rgba(15,32,60,0.06)',
      ...style,
    }}>
      {accent && (
        <div style={{
          position: 'absolute', left: 0, top: 16, bottom: 16, width: 3,
          background: accent, borderRadius: 3,
        }} />
      )}
      {children}
    </div>
  );
}

function SlChip({ children, color = SL.blue, filled }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      fontFamily: SL.sys, fontSize: 11, fontWeight: 600,
      letterSpacing: '0.02em',
      color: filled ? '#fff' : color,
      background: filled ? color : `color-mix(in oklch, ${color} 15%, white)`,
      border: filled ? 'none' : `1px solid color-mix(in oklch, ${color} 30%, transparent)`,
      padding: '3px 9px',
      borderRadius: 999,
    }}>
      {children}
    </span>
  );
}

function SlLabel({ children, style = {} }) {
  return (
    <div style={{
      fontFamily: SL.sys, fontSize: 12, fontWeight: 600,
      color: SL.ink3, letterSpacing: '0.04em', textTransform: 'uppercase',
      ...style,
    }}>{children}</div>
  );
}

function SlGlyph({ name, size = 14 }) {
  const s = { width: size, height: size };
  if (name === 'tram') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M8 3a3 3 0 00-3 3v9a3 3 0 003 3h.5l-1.4 2.5a.75.75 0 101.3.75L10 18.5h4l1.6 2.75a.75.75 0 101.3-.75L15.5 18H16a3 3 0 003-3V6a3 3 0 00-3-3H8zm0 1.5h8c.83 0 1.5.67 1.5 1.5v5h-11V6c0-.83.67-1.5 1.5-1.5zM6.5 12.5h11V15c0 .83-.67 1.5-1.5 1.5H8c-.83 0-1.5-.67-1.5-1.5v-2.5zm2 1.25a1 1 0 100 2 1 1 0 000-2zm7 0a1 1 0 100 2 1 1 0 000-2z"/>
    </svg>
  );
  if (name === 'envelope') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M5 5.5a2.5 2.5 0 00-2.5 2.5v8A2.5 2.5 0 005 18.5h14a2.5 2.5 0 002.5-2.5V8A2.5 2.5 0 0019 5.5H5zm-1 2.5C4 7.45 4.45 7 5 7h14c.55 0 1 .45 1 1v.4l-8 5-8-5V8zm0 2.16l7.6 4.75a.75.75 0 00.8 0L20 10.16V16c0 .55-.45 1-1 1H5c-.55 0-1-.45-1-1v-5.84z"/>
    </svg>
  );
  if (name === 'house') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M11.3 3.26a1 1 0 011.4 0l8 7.5a.75.75 0 01-1.02 1.1L19 11.1V19a2 2 0 01-2 2h-3.5v-5h-3V21H7a2 2 0 01-2-2v-7.9l-.68.76a.75.75 0 11-1.02-1.1l8-7.5z"/>
    </svg>
  );
  if (name === 'server') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M5 4.5A2.5 2.5 0 002.5 7v2A2.5 2.5 0 005 11.5h14A2.5 2.5 0 0021.5 9V7A2.5 2.5 0 0019 4.5H5zm2 2.75a1 1 0 100 2 1 1 0 000-2zm-2 5.25A2.5 2.5 0 002.5 15v2A2.5 2.5 0 005 19.5h14A2.5 2.5 0 0021.5 17v-2a2.5 2.5 0 00-2.5-2.5H5zm2 2.75a1 1 0 100 2 1 1 0 000-2z"/>
    </svg>
  );
  if (name === 'tray') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M6.4 4a2 2 0 00-1.93 1.47L2.55 12.5A3 3 0 002.5 13.3V18a2 2 0 002 2h15a2 2 0 002-2v-4.7c0-.27-.02-.54-.05-.8l-1.92-7.03A2 2 0 0017.6 4H6.4zm0 1.5h11.2c.23 0 .43.15.5.37L19.6 12H17a.75.75 0 00-.6.3l-1.4 1.85h-6L7.6 12.3a.75.75 0 00-.6-.3H4.4l1.5-6.13a.5.5 0 01.5-.37z"/>
    </svg>
  );
  if (name === 'antenna') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 8a4 4 0 00-3.46 6L9.6 13a2.5 2.5 0 114.8 0l1.06 1A4 4 0 0012 8zm-7-1.5a.75.75 0 00-1.2.9 11 11 0 0016.4 0 .75.75 0 10-1.2-.9 9.5 9.5 0 01-14 0zm2.6 2.6a.75.75 0 10-1.2.9 7 7 0 0011.2 0 .75.75 0 10-1.2-.9 5.5 5.5 0 01-8.8 0zM12 11.5A1.5 1.5 0 0010.7 13.7l-1.6 6.5a.75.75 0 101.46.36L11.4 18h1.2l.84 2.56a.75.75 0 101.46-.36l-1.6-6.5A1.5 1.5 0 0012 11.5z"/>
    </svg>
  );
  if (name === 'search') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M11 4a7 7 0 014.95 11.95l4.05 4.05a.75.75 0 11-1.06 1.06l-4.05-4.05A7 7 0 1111 4zm0 1.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11z"/>
    </svg>
  );
  if (name === 'back') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <path d="M15.53 4.47a.75.75 0 00-1.06 0l-7 7a.75.75 0 000 1.06l7 7a.75.75 0 101.06-1.06L9.06 12l6.47-6.47a.75.75 0 000-1.06z"/>
    </svg>
  );
  if (name === 'more') return (
    <svg {...s} viewBox="0 0 24 24" fill="currentColor">
      <circle cx="6" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="18" cy="12" r="1.5"/>
    </svg>
  );
  return null;
}

function SlIconBtn({ glyph }) {
  return (
    <div style={{
      width: 36, height: 36, borderRadius: 99,
      background: 'rgba(255,255,255,0.7)',
      border: `1px solid ${SL.hair}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: SL.ink2,
      boxShadow: '0 1px 2px rgba(15,32,60,0.04)',
    }}>
      <SlGlyph name={glyph} size={15} />
    </div>
  );
}

// ──────────────────────────────────────────────
// 1) INBOX
// ──────────────────────────────────────────────
function SlInbox() {
  return (
    <div style={{ position: 'absolute', inset: 0, color: SL.ink, fontFamily: SL.sys }}>
      <SlBg />
      <div style={{ position: 'relative', padding: '8px 20px 0' }}>
        {/* topbar */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0',
        }}>
          <div>
            <SlLabel style={{ color: SL.ink2 }}>Sonntag · 03 Mai</SlLabel>
            <div style={{
              fontFamily: SL.sys, fontSize: 34, fontWeight: 700,
              letterSpacing: '-0.022em', marginTop: 2, lineHeight: 1.1,
            }}>Inbox</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <SlIconBtn glyph="search" />
            <SlIconBtn glyph="more" />
          </div>
        </div>

        {/* live hero */}
        <SlCard style={{
          marginTop: 12, padding: 0, overflow: 'hidden',
          background: `linear-gradient(180deg, color-mix(in oklch, ${SL.amber} 14%, white) 0%, rgba(255,255,255,0.78) 100%)`,
        }}>
          <div style={{ padding: '14px 16px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <SlChip color={SL.amber}>● Verspätet · +7 Min</SlChip>
            <div style={{ fontFamily: SL.mono, fontSize: 11, color: SL.ink3 }}>vor 12 min</div>
          </div>
          <div style={{ padding: '8px 16px 14px' }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginTop: 4 }}>
              <div style={{
                fontFamily: SL.sys, fontSize: 48, lineHeight: 1, fontWeight: 700,
                letterSpacing: '-0.03em', color: SL.ink,
              }}>06:38</div>
              <div style={{
                fontFamily: SL.sys, fontSize: 16, color: SL.ink3,
                textDecoration: 'line-through', fontWeight: 500,
              }}>06:31</div>
            </div>
            <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                fontFamily: SL.sys, fontSize: 12, fontWeight: 700, color: SL.blue,
                background: `color-mix(in oklch, ${SL.blue} 14%, white)`,
                border: `1px solid color-mix(in oklch, ${SL.blue} 30%, transparent)`,
                padding: '3px 9px', borderRadius: 6,
              }}>RB23</div>
              <div style={{ color: SL.ink2, fontSize: 14 }}>nach Andernach · Gleis 1</div>
            </div>

            {/* progress */}
            <div style={{
              marginTop: 14, height: 5, background: 'rgba(15,32,60,0.08)',
              borderRadius: 99, overflow: 'hidden', position: 'relative',
            }}>
              <div style={{
                position: 'absolute', left: 0, top: 0, bottom: 0, width: '32%',
                background: `linear-gradient(90deg, ${SL.amber}, color-mix(in oklch, ${SL.amber} 60%, transparent))`,
                borderRadius: 99,
              }} />
            </div>
            <div style={{
              marginTop: 6, display: 'flex', justifyContent: 'space-between',
              fontFamily: SL.sys, fontSize: 11.5, color: SL.ink3, fontWeight: 500,
            }}>
              <span>Bad Ems</span>
              <span>Niederlahnstein</span>
            </div>
          </div>
        </SlCard>

        {/* day section */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          margin: '20px 4px 8px',
        }}>
          <div style={{ fontFamily: SL.sys, fontSize: 17, fontWeight: 700, letterSpacing: '-0.01em' }}>
            Heute
          </div>
          <div style={{ fontFamily: SL.sys, fontSize: 12, color: SL.ink3, fontWeight: 500 }}>3 Signale</div>
        </div>

        <SlCard style={{ padding: 0, overflow: 'hidden' }}>
          <SlRow time="08:14" symbol="tram" color={SL.blue} source="dbticker" status="Pünktlich" statusColor={SL.green}
            title="RB23 pünktlich" body="Abfahrt 08:14 · Bad Ems · Gleis 1" />
          <SlRow time="07:48" symbol="envelope" color={SL.violet} source="mailcontrol" status="Neu" statusColor={SL.violet}
            title="Neue Rechnung erkannt" body="DB Vertrieb · 124,80 € · fällig 15.05." unread />
          <SlRow time="07:02" symbol="house" color={SL.green} source="smarthome" status="OK" statusColor={SL.green}
            title="Vorderhaus warm" body="Wohnzimmer 21,4° · Heizung aus" last />
        </SlCard>

        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          margin: '18px 4px 8px',
        }}>
          <div style={{ fontFamily: SL.sys, fontSize: 17, fontWeight: 700, letterSpacing: '-0.01em' }}>
            Gestern
          </div>
          <div style={{ fontFamily: SL.sys, fontSize: 12, color: SL.ink3, fontWeight: 500 }}>9 Signale</div>
        </div>

        <SlCard style={{ padding: 0, overflow: 'hidden' }}>
          <SlRow time="22:41" symbol="server" color={SL.violet} source="system" status="OK" statusColor={SL.green}
            title="Backend reconnected" body="push.barto.cloud · Latenz 84 ms" />
          <SlRow time="18:09" symbol="tram" color={SL.amber} source="dbticker" status="+12 Min" statusColor={SL.amber}
            title="RB23 verspätet" body="Weichenstörung · Koblenz Hbf" last />
        </SlCard>
      </div>

      <SlTabBar active="inbox" />
    </div>
  );
}

function SlRow({ time, symbol, color, source, status, statusColor, title, body, unread, last }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '40px 1fr',
      borderBottom: last ? 'none' : `1px solid ${SL.hair}`,
      padding: '14px 14px',
      gap: 12, alignItems: 'flex-start',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: `color-mix(in oklch, ${color} 16%, white)`,
        color: color,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <SlGlyph name={symbol} size={18} />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{
            fontFamily: SL.sys, fontSize: 11.5, fontWeight: 600, color: SL.ink2,
            textTransform: 'lowercase',
          }}>{source}</div>
          <div style={{ flex: 1 }} />
          <SlChip color={statusColor}>{status}</SlChip>
          {unread && <div style={{ width: 7, height: 7, borderRadius: 99, background: SL.amber }} />}
        </div>
        <div style={{
          fontFamily: SL.sys, fontSize: 16, fontWeight: 600, marginTop: 4,
          letterSpacing: '-0.005em', color: SL.ink,
        }}>{title}</div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 2 }}>
          <div style={{ fontFamily: SL.sys, fontSize: 13.5, color: SL.ink2 }}>{body}</div>
          <div style={{ fontFamily: SL.sys, fontSize: 12, color: SL.ink3, fontWeight: 500 }}>{time}</div>
        </div>
      </div>
    </div>
  );
}

function SlTabBar({ active }) {
  const tabs = [
    { id: 'inbox', label: 'Inbox', glyph: 'tray' },
    { id: 'status', label: 'Status', glyph: 'antenna' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 18,
      background: 'rgba(255,255,255,0.82)',
      backdropFilter: 'blur(22px) saturate(180%)',
      WebkitBackdropFilter: 'blur(22px) saturate(180%)',
      border: `1px solid ${SL.hair}`,
      borderRadius: 22, padding: 5,
      display: 'flex', gap: 5,
      boxShadow: '0 12px 32px rgba(15,32,60,0.10)',
    }}>
      {tabs.map(t => {
        const on = t.id === active;
        return (
          <div key={t.id} style={{
            flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
            gap: 8, padding: '11px 14px', borderRadius: 17,
            background: on ? SL.blue : 'transparent',
            color: on ? '#fff' : SL.ink2,
            fontFamily: SL.sys, fontSize: 14, fontWeight: 600, letterSpacing: '-0.005em',
          }}>
            <SlGlyph name={t.glyph} size={16} />
            {t.label}
          </div>
        );
      })}
    </div>
  );
}

// ──────────────────────────────────────────────
// 2) DETAIL
// ──────────────────────────────────────────────
function SlDetail() {
  return (
    <div style={{ position: 'absolute', inset: 0, color: SL.ink, fontFamily: SL.sys }}>
      <SlBg />
      <div style={{ position: 'relative', padding: '8px 20px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6, color: SL.blue,
            fontFamily: SL.sys, fontSize: 16, fontWeight: 500,
          }}>
            <SlGlyph name="back" size={18} />
            Inbox
          </div>
          <SlIconBtn glyph="more" />
        </div>

        <div style={{ marginTop: 14 }}>
          <SlChip color={SL.amber}>● Verspätung · Hoch</SlChip>
          <div style={{
            fontFamily: SL.sys, fontSize: 30, fontWeight: 700,
            letterSpacing: '-0.022em', marginTop: 12, lineHeight: 1.15,
          }}>
            RB23 nach<br/>
            Andernach
          </div>
          <div style={{
            color: SL.ink3, fontFamily: SL.sys, fontSize: 13, marginTop: 8,
          }}>
            03.05.2026, 06:24 · dbticker.transit
          </div>
        </div>

        <SlCard style={{ marginTop: 16, padding: 0 }} accent={SL.amber}>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 24px 1fr', alignItems: 'center',
            padding: '16px 18px',
          }}>
            <div>
              <SlLabel>Geplant</SlLabel>
              <div style={{
                fontFamily: SL.sys, fontSize: 28, color: SL.ink3, marginTop: 4,
                textDecoration: 'line-through', fontWeight: 600,
              }}>06:31</div>
            </div>
            <div style={{ color: SL.ink3, textAlign: 'center', fontSize: 18 }}>→</div>
            <div>
              <SlLabel style={{ color: SL.amber }}>Neu</SlLabel>
              <div style={{
                fontFamily: SL.sys, fontSize: 38, color: SL.ink, marginTop: 4,
                fontWeight: 700, letterSpacing: '-0.025em',
              }}>06:38</div>
            </div>
          </div>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
            borderTop: `1px solid ${SL.hair}`,
          }}>
            <SlKpi label="Linie" value="RB23" sub="Nr. 12614" />
            <SlKpi label="Gleis" value="1" sub="Bad Ems" border />
            <SlKpi label="Verspätung" value="+7" sub="Minuten" valueColor={SL.amber} border />
          </div>
        </SlCard>

        <SlCard style={{ marginTop: 12 }} accent={SL.amber}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <SlLabel>Grund</SlLabel>
            <SlChip color={SL.amber}>Severity · Hoch</SlChip>
          </div>
          <div style={{
            fontFamily: SL.sys, fontSize: 20, fontWeight: 600, marginTop: 10,
            color: SL.ink, letterSpacing: '-0.01em',
          }}>
            Weichenstörung
          </div>
          <div style={{ fontSize: 14, color: SL.ink2, marginTop: 8, lineHeight: 1.5 }}>
            Du kannst 7 Minuten später losfahren — Anschluss in Niederlahnstein
            laut DB-System weiterhin erreichbar.
          </div>
        </SlCard>

        <SlCard style={{ marginTop: 12 }}>
          <SlLabel>Strecke</SlLabel>
          <div style={{ marginTop: 14, display: 'flex' }}>
            <div style={{
              width: 16, display: 'flex', flexDirection: 'column', alignItems: 'center',
              paddingTop: 4,
            }}>
              <div style={{
                width: 11, height: 11, borderRadius: 99, background: SL.blue,
                boxShadow: `0 0 0 3px color-mix(in oklch, ${SL.blue} 18%, transparent)`,
              }} />
              <div style={{ flex: 1, width: 2, background: SL.hair, margin: '4px 0', borderRadius: 2 }} />
              <div style={{
                width: 11, height: 11, borderRadius: 99, background: 'white',
                border: `2.5px solid ${SL.blue}`,
              }} />
            </div>
            <div style={{ flex: 1, marginLeft: 14 }}>
              <div style={{ fontFamily: SL.sys, fontSize: 16, fontWeight: 600 }}>Bad Ems</div>
              <div style={{ fontSize: 13, color: SL.ink3, marginTop: 2 }}>Einsteigen · 06:38 · Gleis 1</div>
              <div style={{ height: 22 }} />
              <div style={{ fontFamily: SL.sys, fontSize: 16, fontWeight: 600 }}>Niederlahnstein</div>
              <div style={{ fontSize: 13, color: SL.ink3, marginTop: 2 }}>Aussteigen · ca. 06:54</div>
            </div>
          </div>
        </SlCard>

        <SlCard style={{ marginTop: 12 }}>
          <SlLabel>Nachricht</SlLabel>
          <div style={{
            fontFamily: SL.sys, fontSize: 14, color: SL.ink2,
            marginTop: 10, lineHeight: 1.6, whiteSpace: 'pre-line',
          }}>
{`Abfahrt 06:31 → 06:38 (Bad Ems, Gleis 1)
Aussteigen: Niederlahnstein
Grund: Weichen`}
          </div>
        </SlCard>

        <div style={{ height: 30 }} />
      </div>
    </div>
  );
}

function SlKpi({ label, value, sub, valueColor, border }) {
  return (
    <div style={{
      padding: '14px 16px',
      borderLeft: border ? `1px solid ${SL.hair}` : 'none',
    }}>
      <SlLabel>{label}</SlLabel>
      <div style={{
        fontFamily: SL.sys, fontSize: 24, color: valueColor || SL.ink,
        marginTop: 4, fontWeight: 700, letterSpacing: '-0.018em',
      }}>{value}</div>
      <div style={{ fontFamily: SL.sys, fontSize: 12, color: SL.ink3, marginTop: 2 }}>{sub}</div>
    </div>
  );
}

// ──────────────────────────────────────────────
// 3) STATUS
// ──────────────────────────────────────────────
function SlStatus() {
  return (
    <div style={{ position: 'absolute', inset: 0, color: SL.ink, fontFamily: SL.sys }}>
      <SlBg />
      <div style={{ position: 'relative', padding: '8px 20px 0' }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', padding: '8px 0',
        }}>
          <div>
            <SlLabel style={{ color: SL.ink2 }}>System · Live</SlLabel>
            <div style={{
              fontFamily: SL.sys, fontSize: 34, fontWeight: 700,
              letterSpacing: '-0.022em', marginTop: 2, lineHeight: 1.1,
            }}>Status</div>
          </div>
          <SlChip color={SL.green}>● Healthy</SlChip>
        </div>

        {/* health hero */}
        <SlCard style={{ marginTop: 12, padding: 0, overflow: 'hidden' }}>
          <div style={{
            padding: '18px 16px',
            background: `linear-gradient(180deg, color-mix(in oklch, ${SL.green} 16%, white) 0%, rgba(255,255,255,0.78) 100%)`,
          }}>
            <SlLabel style={{ color: SL.green }}>● Alle Systeme nominal</SlLabel>
            <div style={{
              fontFamily: SL.sys, fontSize: 36, marginTop: 6, fontWeight: 700,
              letterSpacing: '-0.022em',
            }}>99,8<span style={{ color: SL.ink3, fontSize: 22, fontWeight: 600 }}>% Uptime</span></div>
            {/* sparkline */}
            <svg viewBox="0 0 280 50" style={{ width: '100%', marginTop: 10, display: 'block' }}>
              <defs>
                <linearGradient id="slSpark" x1="0" x2="0" y1="0" y2="1">
                  <stop offset="0" stopColor={SL.green} stopOpacity="0.35"/>
                  <stop offset="1" stopColor={SL.green} stopOpacity="0"/>
                </linearGradient>
              </defs>
              <path d="M0,38 L20,32 L40,34 L60,28 L80,30 L100,22 L120,26 L140,18 L160,24 L180,20 L200,28 L220,16 L240,22 L260,14 L280,20 L280,50 L0,50 Z" fill="url(#slSpark)"/>
              <path d="M0,38 L20,32 L40,34 L60,28 L80,30 L100,22 L120,26 L140,18 L160,24 L180,20 L200,28 L220,16 L240,22 L260,14 L280,20" fill="none" stroke={SL.green} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <div style={{
              display: 'flex', justifyContent: 'space-between',
              fontFamily: SL.sys, fontSize: 11.5, color: SL.ink3, fontWeight: 500, marginTop: 4,
            }}>
              <span>−30 Tage</span><span>Jetzt</span>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', borderTop: `1px solid ${SL.hair}` }}>
            <SlKpi label="Latenz" value="84" sub="ms · p50" />
            <SlKpi label="Pushes" value="12" sub="heute" border />
            <SlKpi label="Queue" value="0" sub="pending" border />
          </div>
        </SlCard>

        <SlCard style={{ marginTop: 12 }} accent={SL.blue}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <SlLabel>APNs</SlLabel>
            <SlChip color={SL.green}>● Registriert</SlChip>
          </div>
          <div style={{
            marginTop: 10,
            fontFamily: SL.mono, fontSize: 11.5, color: SL.ink2,
            background: 'rgba(15,32,60,0.04)', border: `1px solid ${SL.hair}`,
            borderRadius: 10, padding: '10px 12px', wordBreak: 'break-all', lineHeight: 1.55,
          }}>
            8a4f29b1c7e5d86f3a2e91d4b6c8f0a1<br/>
            d9e2c4b6a8f1d3e5b7c9a2f4d6e8b1c3
          </div>
        </SlCard>

        <SlCard style={{ marginTop: 12 }} accent={SL.green}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <SlLabel>Backend</SlLabel>
            <SlChip color={SL.green}>● Verbunden</SlChip>
          </div>
          <SlKv k="Device" v="#142" />
          <SlKv k="Endpoint" v="push.barto.cloud" mono />
          <SlKv k="Environment" v="production" />
        </SlCard>

        <SlCard style={{ marginTop: 12 }}>
          <SlLabel>App</SlLabel>
          <SlKv k="Bundle-ID" v="cloud.barto.bartolink" mono />
          <SlKv k="Version" v="1.4.0 (220)" />
          <SlKv k="APNs-Env" v="production" />
        </SlCard>
      </div>

      <SlTabBar active="status" />
    </div>
  );
}

function SlKv({ k, v, mono }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '10px 0', borderBottom: `1px solid ${SL.hair}`,
      fontFamily: SL.sys, fontSize: 14,
    }}>
      <div style={{ color: SL.ink2 }}>{k}</div>
      <div style={{
        color: SL.ink, fontFamily: mono ? SL.mono : SL.sys,
        fontSize: mono ? 12.5 : 14, fontWeight: mono ? 400 : 500,
      }}>{v}</div>
    </div>
  );
}

Object.assign(window, { SlInbox, SlDetail, SlStatus });
