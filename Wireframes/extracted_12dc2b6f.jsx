// All 20 Apple Watch screens for the Vestel Divisé flow.
// Each screen is a stateless render function. State (selected hardness,
// timer position, etc.) is threaded in via props with sensible defaults so
// the same screen renders fine in the static gallery AND the prototype.
//
// Visual language: dark face (#1a1a1c), Apple-system red (#FF3B30) /
// orange (#FF9500) accents, SF system font, big-number countdown rings.

const { useState, useEffect, useRef } = React;

// ─── tiny helpers ────────────────────────────────────────────────────────────

// SVG ring used in setup-summary, status pips, etc. Single arc.
function Ring({ size, stroke = 10, color, track, progress = 1, startAngle = -90 }) {
  const r = (size - stroke) / 2;
  const cx = size / 2, cy = size / 2;
  const circ = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} style={{ display: 'block' }}>
      <circle cx={cx} cy={cy} r={r} stroke={track || WATCH.ringTrack} strokeWidth={stroke} fill="none" />
      <circle
        cx={cx} cy={cy} r={r}
        stroke={color || WATCH.red} strokeWidth={stroke} fill="none"
        strokeLinecap="round"
        strokeDasharray={`${circ * progress} ${circ}`}
        transform={`rotate(${startAngle} ${cx} ${cy})`}
      />
    </svg>
  );
}

// The signature dual-arc cooking timer (red outer arc + orange inner arc on
// the same radius via a stroke gradient; matches the source mock's vibe).
function TimerRing({ size = 168, stroke = 7, progress = 1, dim = false }) {
  const r = (size - stroke) / 2;
  const cx = size / 2, cy = size / 2;
  const circ = 2 * Math.PI * r;
  const gid = 'tg-' + Math.round(progress * 1000);
  return (
    <svg width={size} height={size} style={{ display: 'block', transform: 'rotate(-90deg)' }}>
      <defs>
        <linearGradient id={gid} x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={dim ? '#6a1a14' : WATCH.red} />
          <stop offset="100%" stopColor={dim ? '#7a4400' : WATCH.orange} />
        </linearGradient>
      </defs>
      <circle cx={cx} cy={cy} r={r} stroke={WATCH.ringTrack} strokeWidth={stroke} fill="none" />
      <circle
        cx={cx} cy={cy} r={r}
        stroke={`url(#${gid})`} strokeWidth={stroke} fill="none"
        strokeLinecap="round"
        strokeDasharray={`${circ * progress} ${circ}`}
      />
      {/* end-cap dots — give it the dial-knob look */}
      {progress > 0.02 && (
        <>
          <circle cx={cx + r} cy={cy} r={stroke / 1.4}
            fill={dim ? '#6a1a14' : WATCH.red}
            transform={`rotate(0 ${cx} ${cy})`} />
          <circle cx={cx + r} cy={cy} r={stroke / 1.4}
            fill={dim ? '#7a4400' : WATCH.orange}
            transform={`rotate(${360 * progress} ${cx} ${cy})`} />
        </>
      )}
    </svg>
  );
}

// Compact representation of the 3-compartment cooker (used in summary,
// notifications, history).
function CookerGlyph({ states = ['red','red','red'], size = 18, gap = 6 }) {
  const color = (s) => s === 'red' ? WATCH.red : s === 'orange' ? WATCH.orange : s === 'gray' ? 'rgba(255,255,255,0.18)' : s;
  return (
    <div style={{ display: 'flex', gap, alignItems: 'center' }}>
      {states.map((s, i) => (
        <div key={i} style={{
          width: size * 1.6, height: size * 2.1,
          borderRadius: size * 0.32,
          background: 'rgba(255,255,255,0.06)',
          border: `2px solid ${color(s)}`,
          display: 'flex', flexDirection: 'column', justifyContent: 'space-evenly',
          alignItems: 'center', padding: '4px 0',
        }}>
          <div style={{ width: size * 0.7, height: size * 0.7, borderRadius: '50%',
            background: s === 'gray' ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.7)' }} />
          <div style={{ width: size * 0.7, height: size * 0.7, borderRadius: '50%',
            background: s === 'gray' ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.7)' }} />
        </div>
      ))}
    </div>
  );
}

// Centered title row.
function ScreenCenter({ children, style }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center',
      ...style,
    }}>{children}</div>
  );
}

// Pill button (Start / Done / etc.).
function PillBtn({ children, color = WATCH.red, onClick, style }) {
  return (
    <button
      onClick={onClick}
      style={{
        background: color, color: '#fff', border: 'none',
        height: 36, padding: '0 22px', borderRadius: 18,
        fontFamily: WATCH.font, fontSize: 15, fontWeight: 600,
        cursor: 'pointer', ...style,
      }}>{children}</button>
  );
}

// Round icon-button (stop / pause / etc.).
function IconBtn({ color = WATCH.red, children, onClick, size = 44 }) {
  return (
    <button onClick={onClick} style={{
      width: size, height: size, borderRadius: '50%',
      background: color, border: 'none', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', padding: 0,
    }}>{children}</button>
  );
}

// ─── 1. WatchHome (app launcher / honeycomb grid) ───────────────────────────
function S01_Home({ onLaunch }) {
  // Apple-Watch honeycomb-ish grid. The Divisé icon sits at center
  // (red, slightly enlarged) so the user knows where they're going.
  const dots = [
    { x: 50, y: 22, c: '#0A84FF', d: 14 },                  // Calendar-ish
    { x: 90, y: 36, c: '#34C759', d: 14 },                  // Activity-ish
    { x: 130, y: 22, c: '#FF9500', d: 14 },                 // Music
    { x: 30, y: 60, c: '#5856D6', d: 16 },                  // Mail
    { x: 70, y: 76, c: WATCH.red, d: 26, divise: true },    // Divisé (focused)
    { x: 110, y: 76, c: '#FFD60A', d: 14 },                 // Reminders
    { x: 150, y: 60, c: '#FF2D55', d: 14 },                 // Heart
    { x: 50, y: 110, c: '#64D2FF', d: 14 },                 // Weather
    { x: 90, y: 124, c: '#BF5AF2', d: 14 },                 // Photos
    { x: 130, y: 110, c: '#30D158', d: 14 },                // Maps
  ];
  return (
    <>
      <WatchTime time="10:24" />
      <div style={{
        position: 'absolute', inset: 0, padding: '40px 30px 20px',
        overflow: 'hidden',
      }}>
        <svg viewBox="0 0 180 180" style={{ width: '100%', height: '100%' }}>
          {dots.map((d, i) => (
            <g key={i}>
              <circle
                cx={d.x} cy={d.y} r={d.d}
                fill={d.c}
                opacity={d.divise ? 1 : 0.85}
                style={{ filter: d.divise ? `drop-shadow(0 0 6px ${WATCH.red}66)` : 'none' }}
              />
              {d.divise && (
                <>
                  {/* tiny steam-and-egg icon */}
                  <ellipse cx={d.x} cy={d.y + 4} rx="8" ry="10" fill="#fff" opacity="0.95" />
                  <path d={`M ${d.x - 4} ${d.y - 10} q 2 -4 0 -8 M ${d.x} ${d.y - 12} q 2 -4 0 -8 M ${d.x + 4} ${d.y - 10} q 2 -4 0 -8`}
                    stroke="#fff" strokeWidth="1.4" fill="none" strokeLinecap="round" opacity="0.85" />
                </>
              )}
            </g>
          ))}
        </svg>
      </div>
      {onLaunch && (
        <button onClick={onLaunch} style={{
          position: 'absolute', inset: 0, background: 'transparent', border: 'none', cursor: 'pointer',
        }} aria-label="Open Divisé" />
      )}
    </>
  );
}

// ─── 2. WatchSplash (brand) ─────────────────────────────────────────────────
function S02_Splash() {
  return (
    <ScreenCenter>
      <div style={{
        fontFamily: '"Times New Roman", "Cormorant Garamond", Georgia, serif',
        fontSize: 11, fontWeight: 700, letterSpacing: 0.4,
        display: 'flex', alignItems: 'baseline', gap: 4,
      }}>
        <span style={{ color: WATCH.red, fontFamily: WATCH.font, fontWeight: 900, fontSize: 13, letterSpacing: 0.5 }}>VESTEL</span>
        <span style={{ fontStyle: 'italic', fontSize: 16 }}>Divisé</span>
      </div>
      {/* product silhouette — placeholder */}
      <svg width="150" height="80" viewBox="0 0 150 80" style={{ marginTop: 14 }}>
        <ellipse cx="75" cy="65" rx="62" ry="6" fill="#000" opacity="0.5" />
        <rect x="20" y="30" width="110" height="32" rx="4" fill="#2a2a2c" stroke="#444" strokeWidth="0.5" />
        {[28, 62, 96].map((x, i) => (
          <g key={i}>
            <rect x={x} y="14" width="26" height="22" rx="3" fill="rgba(255,255,255,0.08)" stroke="rgba(255,255,255,0.2)" strokeWidth="0.5" />
            <ellipse cx={x + 9} cy="26" rx="3.2" ry="4" fill="#b8865a" />
            <ellipse cx={x + 17} cy="26" rx="3.2" ry="4" fill="#c89870" />
          </g>
        ))}
      </svg>
      {/* loading dots */}
      <div style={{ display: 'flex', gap: 5, marginTop: 18 }}>
        {[0,1,2].map(i => (
          <div key={i} style={{
            width: 5, height: 5, borderRadius: '50%',
            background: i === 1 ? WATCH.red : 'rgba(255,255,255,0.3)',
          }} />
        ))}
      </div>
    </ScreenCenter>
  );
}

// ─── 3. WatchPairing ────────────────────────────────────────────────────────
function S03_Pairing({ onCancel }) {
  return (
    <>
      <WatchTime time="10:24" color={WATCH.textDim} />
      <ScreenCenter>
        <div style={{ position: 'relative', width: 110, height: 110, marginTop: -10 }}>
          {/* pulsing concentric rings */}
          {[0,1,2].map(i => (
            <div key={i} style={{
              position: 'absolute', inset: 0,
              border: `1.5px solid ${WATCH.red}`,
              borderRadius: '50%',
              opacity: 0.5 - i * 0.15,
              transform: `scale(${1 + i * 0.18})`,
              animation: `divisePulse 1.8s ease-out ${i * 0.6}s infinite`,
            }} />
          ))}
          <div style={{
            position: 'absolute', inset: 32,
            borderRadius: '50%',
            background: WATCH.red,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 0 24px ${WATCH.red}88`,
          }}>
            <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
              <path d="M4 11 q3.5 -3.5 7 0 M7 11 q1.5 -1.5 3 0" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" />
              <circle cx="11" cy="14" r="1.2" fill="#fff" />
            </svg>
          </div>
        </div>
        <div style={{ fontSize: 14, fontWeight: 600, marginTop: 14 }}>Searching…</div>
        <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 2 }}>Looking for Divisé</div>
      </ScreenCenter>
      {onCancel && (
        <div style={{ position: 'absolute', bottom: 10, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}>
          <button onClick={onCancel} style={{
            background: 'transparent', border: 'none', color: WATCH.textDim, fontSize: 12, cursor: 'pointer',
            fontFamily: WATCH.font,
          }}>Cancel</button>
        </div>
      )}
    </>
  );
}

// ─── 4. WatchConnected ──────────────────────────────────────────────────────
function S04_Connected({ onContinue }) {
  return (
    <>
      <WatchTime time="10:24" color={WATCH.textDim} />
      <ScreenCenter>
        <div style={{
          width: 64, height: 64, borderRadius: '50%',
          background: WATCH.green,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 0 24px ${WATCH.green}55`,
        }}>
          <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
            <path d="M8 16 l5 5 l11 -11" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 14 }}>Connected</div>
        <div style={{ fontSize: 12, color: WATCH.textDim, marginTop: 4 }}>Divisé · Kitchen</div>
        {onContinue && (
          <div style={{ marginTop: 16 }}>
            <PillBtn onClick={onContinue} color={WATCH.green}>Continue</PillBtn>
          </div>
        )}
      </ScreenCenter>
    </>
  );
}

// ─── 5. WatchWaterLow (error) ───────────────────────────────────────────────
function S05_WaterLow({ onRefill }) {
  return (
    <>
      {/* top banner */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 38,
        background: WATCH.red,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 12, fontWeight: 700, letterSpacing: 0.3,
      }}>! WATER LOW</div>
      <ScreenCenter style={{ paddingTop: 30 }}>
        {/* droplet with low fill */}
        <svg width="60" height="78" viewBox="0 0 60 78">
          <defs>
            <clipPath id="drop">
              <path d="M30 4 C 18 24, 6 38, 6 52 a 24 24 0 0 0 48 0 C 54 38, 42 24, 30 4 Z" />
            </clipPath>
          </defs>
          <path d="M30 4 C 18 24, 6 38, 6 52 a 24 24 0 0 0 48 0 C 54 38, 42 24, 30 4 Z"
            fill="none" stroke="rgba(255,255,255,0.4)" strokeWidth="2" />
          <rect x="0" y="60" width="60" height="18" fill={WATCH.red} opacity="0.7" clipPath="url(#drop)" />
        </svg>
        <div style={{ fontSize: 14, fontWeight: 600, marginTop: 10 }}>Add water</div>
        <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 4, textAlign: 'center', padding: '0 24px' }}>
          Min. 60 ml needed for 3 eggs
        </div>
        {onRefill && (
          <div style={{ marginTop: 12 }}>
            <PillBtn onClick={onRefill}>I refilled</PillBtn>
          </div>
        )}
      </ScreenCenter>
    </>
  );
}

// ─── 6. WatchWaterOk ────────────────────────────────────────────────────────
function S06_WaterOk({ onContinue }) {
  return (
    <>
      <WatchTime time="10:25" color={WATCH.textDim} />
      <ScreenCenter>
        <svg width="60" height="78" viewBox="0 0 60 78">
          <defs>
            <clipPath id="drop2">
              <path d="M30 4 C 18 24, 6 38, 6 52 a 24 24 0 0 0 48 0 C 54 38, 42 24, 30 4 Z" />
            </clipPath>
          </defs>
          <path d="M30 4 C 18 24, 6 38, 6 52 a 24 24 0 0 0 48 0 C 54 38, 42 24, 30 4 Z"
            fill="none" stroke="rgba(255,255,255,0.4)" strokeWidth="2" />
          <rect x="0" y="20" width="60" height="58" fill={WATCH.blue} opacity="0.85" clipPath="url(#drop2)" />
          <rect x="0" y="22" width="60" height="3" fill="rgba(255,255,255,0.4)" clipPath="url(#drop2)" />
        </svg>
        <div style={{ fontSize: 14, fontWeight: 600, marginTop: 10 }}>Water OK</div>
        <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 4 }}>180 ml</div>
        {onContinue && (
          <div style={{ marginTop: 12 }}>
            <PillBtn onClick={onContinue} color={WATCH.blue}>Continue</PillBtn>
          </div>
        )}
      </ScreenCenter>
    </>
  );
}

// ─── 7. WatchPresets ────────────────────────────────────────────────────────
// Quick-start list. The top row ("Last time") is the default — pre-selected
// in red so a single tap ("Use") jumps straight to the summary. "Custom…"
// at the bottom drops the user into the manual compartment-by-compartment
// flow.
function S_Presets({ selectedKey = 'last', onUsePreset, onCustom, onSelect }) {
  const presets = [
    { key: 'last',   label: 'Last time', sub: 'H · M · S', time: '5:30', states: ['hard','medium','soft'] },
    { key: 'hard',   label: 'All hard',  sub: '3 × hard',  time: '5:30', states: ['hard','hard','hard'] },
    { key: 'med',    label: 'All medium',sub: '3 × medium',time: '4:30', states: ['medium','medium','medium'] },
    { key: 'soft',   label: 'All soft',  sub: '3 × soft',  time: '3:30', states: ['soft','soft','soft'] },
  ];
  const colorFor = (h) => h === 'hard' ? WATCH.red : h === 'medium' ? WATCH.orange : WATCH.yellow;
  return (
    <>
      <div style={{
        position: 'absolute', top: 10, left: 0, right: 0,
        textAlign: 'center', fontSize: 12, fontWeight: 700,
      }}>Presets</div>
      <div style={{
        position: 'absolute', top: 32, bottom: 36, left: 8, right: 8,
        overflow: 'hidden',
      }}>
        {presets.map((p) => {
          const active = p.key === selectedKey;
          return (
            <div key={p.key}
              onClick={() => onSelect && onSelect(p.key)}
              style={{
                display: 'flex', alignItems: 'center', gap: 8,
                padding: '6px 8px', marginBottom: 3,
                background: active ? 'rgba(255,59,48,0.18)' : 'rgba(255,255,255,0.05)',
                border: active ? `1.5px solid ${WATCH.red}` : '1.5px solid transparent',
                borderRadius: 9,
                cursor: onSelect ? 'pointer' : 'default',
              }}>
              {/* mini compartment glyph */}
              <div style={{ display: 'flex', gap: 2, flex: 'none' }}>
                {p.states.map((s, i) => (
                  <div key={i} style={{
                    width: 8, height: 14, borderRadius: 2,
                    border: `1.5px solid ${colorFor(s)}`,
                  }} />
                ))}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 11, fontWeight: 600, lineHeight: 1.1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {p.label}
                </div>
                <div style={{ fontSize: 9, color: WATCH.textDim, marginTop: 1 }}>{p.sub}</div>
              </div>
              <div style={{ fontSize: 10, color: active ? WATCH.red : WATCH.textDim, fontWeight: 600 }}>
                {p.time}
              </div>
            </div>
          );
        })}
        <div onClick={onCustom} style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: '4px 8px',
          fontSize: 10, color: WATCH.textDim, fontWeight: 500,
          cursor: onCustom ? 'pointer' : 'default',
        }}>+ Custom…</div>
      </div>
      {/* Use button — confirms the highlighted preset */}
      <div style={{ position: 'absolute', bottom: 6, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}>
        <button onClick={onUsePreset} style={{
          background: WATCH.red, color: '#fff', border: 'none',
          height: 26, padding: '0 18px', borderRadius: 13,
          fontFamily: WATCH.font, fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>Use</button>
      </div>
    </>
  );
}

// ─── 8. WatchCompartment (existing screen) ──────────────────────────────────
function S07_Compartment({ states = ['red','orange','gray'], onEdit, onContinue }) {
  const color = (s) => s === 'red' ? WATCH.red : s === 'orange' ? WATCH.orange : 'rgba(255,255,255,0.18)';
  return (
    <ScreenCenter>
      <div style={{ display: 'flex', gap: 10 }}>
        {states.map((s, i) => (
          <div key={i} style={{
            width: 40, height: 80,
            borderRadius: 9,
            background: 'rgba(255,255,255,0.05)',
            border: `2.5px solid ${color(s)}`,
            display: 'flex', flexDirection: 'column', justifyContent: 'space-evenly',
            alignItems: 'center', padding: '6px 0',
            transition: 'border-color .2s',
            cursor: onEdit ? 'pointer' : 'default',
          }}>
            <div style={{ width: 20, height: 20, borderRadius: '50%',
              background: s === 'gray' ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.78)' }} />
            <div style={{ width: 20, height: 20, borderRadius: '50%',
              background: s === 'gray' ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.78)' }} />
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 18 }}>
        <button onClick={onEdit} style={{
          background: 'rgba(255,255,255,0.12)', color: '#fff', border: 'none',
          height: 28, padding: '0 14px', borderRadius: 14,
          fontFamily: WATCH.font, fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>Edit</button>
        <button onClick={onContinue} style={{
          background: 'rgba(255,255,255,0.12)', color: '#fff', border: 'none',
          height: 28, padding: '0 14px', borderRadius: 14,
          fontFamily: WATCH.font, fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>Continue</button>
      </div>
    </ScreenCenter>
  );
}

// ─── 8/9/10. WatchHardness picker (3 variants by slot) ──────────────────────
const HARDNESS = [
  { key: 'hard',   label: 'Hard',   minutes: '5:30' },
  { key: 'medium', label: 'Medium', minutes: '4:30' },
  { key: 'soft',   label: 'Soft',   minutes: '3:30' },
];

function HardnessPicker({ slot, total = 3, selected = 'medium', onDone, onSelect }) {
  // Wheel picker — selected in middle, others above/below dimmed.
  const idx = HARDNESS.findIndex(h => h.key === selected);
  return (
    <>
      <div style={{
        position: 'absolute', top: 10, left: 0, right: 0,
        textAlign: 'center', fontSize: 11, color: WATCH.textDim, fontWeight: 600, letterSpacing: 0.3,
      }}>SLOT {slot} OF {total}</div>
      <ScreenCenter>
        <div style={{
          width: 170, height: 130,
          border: '1.5px solid rgba(255,255,255,0.18)',
          borderRadius: 14,
          position: 'relative',
          display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center',
          overflow: 'hidden',
        }}>
          {/* prev option */}
          {HARDNESS[idx - 1] && (
            <div style={{ position: 'absolute', top: 8, fontSize: 13, color: WATCH.textMute }}>
              {HARDNESS[idx - 1].label}
            </div>
          )}
          {/* current */}
          <div style={{ fontSize: 26, fontWeight: 600, letterSpacing: 0.2 }}>
            {HARDNESS[idx].label}
          </div>
          <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 2 }}>
            {HARDNESS[idx].minutes}
          </div>
          {/* next option */}
          {HARDNESS[idx + 1] && (
            <div style={{ position: 'absolute', bottom: 8, fontSize: 13, color: WATCH.textMute }}>
              {HARDNESS[idx + 1].label}
            </div>
          )}
        </div>
        <button onClick={onDone} style={{
          marginTop: 14,
          background: 'rgba(255,255,255,0.15)', color: '#fff', border: 'none',
          height: 28, padding: '0 22px', borderRadius: 14,
          fontFamily: WATCH.font, fontSize: 12, fontWeight: 600, cursor: 'pointer',
        }}>{slot === total ? 'Done' : 'Next'}</button>
      </ScreenCenter>
    </>
  );
}
const S08_Hardness1 = (p) => <HardnessPicker slot={1} selected="hard"   {...p} />;
const S09_Hardness2 = (p) => <HardnessPicker slot={2} selected="medium" {...p} />;
const S10_Hardness3 = (p) => <HardnessPicker slot={3} selected="soft"   {...p} />;

// ─── 11. WatchSummary ───────────────────────────────────────────────────────
function S11_Summary({ hardness = ['hard','medium','soft'], onStart, onEdit }) {
  const colorFor = (h) => h === 'hard' ? WATCH.red : h === 'medium' ? WATCH.orange : WATCH.yellow;
  const labelFor = (h) => h === 'hard' ? 'H' : h === 'medium' ? 'M' : 'S';
  const minsFor  = (h) => h === 'hard' ? '5:30' : h === 'medium' ? '4:30' : '3:30';
  const longest = ['soft','medium','hard'].find(k => hardness.includes(k));
  // longest comes from finding the hardest selected; defaults to 5:30 here.
  const totalMins = hardness.includes('hard') ? '5:30'
                   : hardness.includes('medium') ? '4:30' : '3:30';
  return (
    <>
      <div style={{
        position: 'absolute', top: 10, left: 0, right: 0,
        textAlign: 'center', fontSize: 11, color: WATCH.textDim, fontWeight: 600, letterSpacing: 0.3,
      }}>READY TO COOK</div>
      <ScreenCenter>
        <div style={{ display: 'flex', gap: 10, marginTop: -4 }}>
          {hardness.map((h, i) => (
            <div key={i} style={{
              width: 38, height: 70,
              borderRadius: 8,
              border: `2px solid ${colorFor(h)}`,
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'space-between',
              padding: '6px 0 4px',
            }}>
              <div style={{ width: 18, height: 18, borderRadius: '50%', background: 'rgba(255,255,255,0.75)' }} />
              <div style={{ fontSize: 11, fontWeight: 700, color: colorFor(h) }}>{labelFor(h)}</div>
            </div>
          ))}
        </div>
        <div style={{ fontSize: 13, marginTop: 10, color: WATCH.textDim }}>
          Total <span style={{ color: '#fff', fontWeight: 600 }}>{totalMins}</span>
        </div>
        <div style={{ marginTop: 10 }}>
          <PillBtn onClick={onStart}>Start</PillBtn>
        </div>
      </ScreenCenter>
    </>
  );
}

// ─── 12. WatchStart (existing screen) ───────────────────────────────────────
function S12_Start({ onStart }) {
  return (
    <ScreenCenter style={{ paddingTop: 12 }}>
      <div style={{ position: 'relative', width: 168, height: 168, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <TimerRing size={168} stroke={7} progress={1} />
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontSize: 32, fontWeight: 600, letterSpacing: 0.5 }}>5:30</div>
          <div style={{ fontSize: 13, color: WATCH.textDim, marginTop: 2 }}>3:30</div>
        </div>
      </div>
      <button onClick={onStart} style={{
        marginTop: 10, height: 36, padding: '0 36px',
        background: WATCH.red, color: '#fff', border: 'none', borderRadius: 18,
        fontFamily: WATCH.font, fontSize: 16, fontWeight: 600, cursor: 'pointer',
      }}>Start</button>
    </ScreenCenter>
  );
}

// ─── 13. WatchPreheat ───────────────────────────────────────────────────────
function S13_Preheat({ onSkip }) {
  return (
    <>
      <WatchTime time="10:26" color={WATCH.textDim} />
      <ScreenCenter>
        <div style={{ position: 'relative', width: 90, height: 90 }}>
          {/* steam wisps */}
          <svg width="90" height="40" viewBox="0 0 90 40" style={{ position: 'absolute', top: -6, left: 0 }}>
            {[0,1,2].map(i => (
              <path key={i}
                d={`M ${25 + i * 20} 36 q -3 -10 0 -18 q 3 -8 0 -16`}
                stroke={WATCH.orange} strokeWidth="2" fill="none" strokeLinecap="round"
                opacity={0.7 - i * 0.15}>
                <animateTransform attributeName="transform" type="translate"
                  values="0 4; 0 -4; 0 4" dur={`${2 + i * 0.3}s`} repeatCount="indefinite" />
              </path>
            ))}
          </svg>
          {/* pot */}
          <div style={{
            position: 'absolute', bottom: 0, left: '50%', transform: 'translateX(-50%)',
            width: 70, height: 44, borderRadius: '0 0 14px 14px',
            background: 'linear-gradient(to bottom, #444, #2a2a2c)',
            border: '1.5px solid rgba(255,255,255,0.15)',
            overflow: 'hidden',
          }}>
            {/* boiling water */}
            <div style={{
              position: 'absolute', inset: '6px 4px 4px 4px',
              background: WATCH.orange, opacity: 0.4, borderRadius: 6,
              animation: 'diviseBoil 1.4s ease-in-out infinite alternate',
            }} />
          </div>
        </div>
        <div style={{ fontSize: 14, fontWeight: 600, marginTop: 12 }}>Heating water</div>
        <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 4 }}>~ 0:45 to boil</div>
      </ScreenCenter>
    </>
  );
}

// ─── 14. WatchRunning (existing) ────────────────────────────────────────────
function S14_Running({ remaining = '4:00', subRemaining = '3:30', progress = 0.73, onStop, onPause }) {
  return (
    <ScreenCenter style={{ paddingTop: 12 }}>
      <div style={{ position: 'relative', width: 168, height: 168, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <TimerRing size={168} stroke={7} progress={progress} />
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontSize: 32, fontWeight: 600, letterSpacing: 0.5 }}>{remaining}</div>
          <div style={{ fontSize: 13, color: WATCH.textDim, marginTop: 2 }}>{subRemaining}</div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 12, marginTop: 10 }}>
        <IconBtn onClick={onStop} size={36} color={WATCH.red}>
          <div style={{ width: 12, height: 12, background: '#fff', borderRadius: 2 }} />
        </IconBtn>
        <IconBtn onClick={onPause} size={36} color={WATCH.red}>
          <div style={{ display: 'flex', gap: 3 }}>
            <div style={{ width: 4, height: 12, background: '#fff', borderRadius: 1 }} />
            <div style={{ width: 4, height: 12, background: '#fff', borderRadius: 1 }} />
          </div>
        </IconBtn>
      </div>
    </ScreenCenter>
  );
}

// ─── 15. WatchPaused ────────────────────────────────────────────────────────
function S15_Paused({ onStop, onResume }) {
  return (
    <ScreenCenter style={{ paddingTop: 12 }}>
      <div style={{ position: 'relative', width: 168, height: 168, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <TimerRing size={168} stroke={7} progress={0.6} dim />
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontSize: 30, fontWeight: 600, letterSpacing: 0.5, color: WATCH.textDim }}>3:12</div>
          <div style={{ fontSize: 10, color: WATCH.orange, marginTop: 4, fontWeight: 700, letterSpacing: 0.6 }}>PAUSED</div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 12, marginTop: 10 }}>
        <IconBtn onClick={onStop} size={36} color="rgba(255,255,255,0.15)">
          <div style={{ width: 12, height: 12, background: '#fff', borderRadius: 2 }} />
        </IconBtn>
        <IconBtn onClick={onResume} size={36} color={WATCH.red}>
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 2 L12 7 L3 12 Z" fill="#fff" /></svg>
        </IconBtn>
      </div>
    </ScreenCenter>
  );
}

// ─── 16. WatchCancelConfirm ─────────────────────────────────────────────────
function S16_CancelConfirm({ onCancel, onConfirm }) {
  return (
    <ScreenCenter style={{ padding: '20px 18px' }}>
      <svg width="36" height="36" viewBox="0 0 36 36">
        <circle cx="18" cy="18" r="16" fill={WATCH.red} />
        <path d="M18 9 v11 M18 25 v0.5" stroke="#fff" strokeWidth="3" strokeLinecap="round" />
      </svg>
      <div style={{ fontSize: 15, fontWeight: 600, marginTop: 8, textAlign: 'center' }}>Stop cooking?</div>
      <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 4, textAlign: 'center' }}>
        Eggs will be undercooked
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 12, width: '100%' }}>
        <button onClick={onCancel} style={{
          flex: 1, background: 'rgba(255,255,255,0.15)', color: '#fff', border: 'none',
          height: 32, borderRadius: 16, fontSize: 13, fontWeight: 600, cursor: 'pointer',
          fontFamily: WATCH.font,
        }}>Keep</button>
        <button onClick={onConfirm} style={{
          flex: 1, background: WATCH.red, color: '#fff', border: 'none',
          height: 32, borderRadius: 16, fontSize: 13, fontWeight: 600, cursor: 'pointer',
          fontFamily: WATCH.font,
        }}>Stop</button>
      </div>
    </ScreenCenter>
  );
}

// ─── 17. WatchNotification ──────────────────────────────────────────────────
function S17_Notification({ onOpen }) {
  return (
    <>
      <div style={{
        position: 'absolute', top: 8, left: 0, right: 0,
        textAlign: 'center', fontSize: 11, color: WATCH.textDim, letterSpacing: 0.3,
      }}>now · NOTIFICATION</div>
      <div style={{
        position: 'absolute', left: 12, right: 12, top: 38,
        background: '#2c2c2e', borderRadius: 16,
        padding: '12px 14px',
        boxShadow: '0 4px 14px rgba(0,0,0,0.4)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
          <div style={{ width: 16, height: 16, borderRadius: 4, background: WATCH.red,
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 800 }}>D</div>
          <div style={{ fontSize: 10, color: WATCH.textDim, letterSpacing: 0.3 }}>DIVISÉ</div>
        </div>
        <div style={{ fontSize: 14, fontWeight: 600, lineHeight: 1.2 }}>1 min left</div>
        <div style={{ fontSize: 11, color: WATCH.textDim, marginTop: 4, lineHeight: 1.3 }}>
          Soft eggs almost done. Tap to view.
        </div>
      </div>
      <button onClick={onOpen} style={{
        position: 'absolute', bottom: 12, left: 12, right: 12,
        background: WATCH.red, color: '#fff', border: 'none',
        height: 32, borderRadius: 16, fontSize: 13, fontWeight: 600, cursor: 'pointer',
        fontFamily: WATCH.font,
      }}>Open</button>
    </>
  );
}

// ─── 18. WatchDone (existing) ───────────────────────────────────────────────
function S18_Done({ onDismiss }) {
  return (
    <ScreenCenter style={{ paddingTop: 12 }}>
      <div style={{ position: 'relative', width: 168, height: 168, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Ring size={168} stroke={7} progress={1} color="rgba(255,255,255,0.18)" track="rgba(255,255,255,0.18)" />
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontSize: 26, fontWeight: 600 }}>Done!</div>
          <div style={{ fontSize: 12, color: WATCH.textDim, marginTop: 2 }}>0:00</div>
        </div>
      </div>
      {/* dismiss alarm slider */}
      <div onClick={onDismiss} style={{
        marginTop: 10, width: 180, height: 28, borderRadius: 14,
        background: 'rgba(255,255,255,0.15)',
        display: 'flex', alignItems: 'center',
        cursor: 'pointer', position: 'relative',
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: '50%', background: WATCH.red,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flex: 'none',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M3 5 a4 4 0 0 1 8 0 v3 l1 2 H2 l1 -2 z" fill="#fff" />
            <path d="M5 11 a2 2 0 0 0 4 0" fill="#fff" />
          </svg>
        </div>
        <div style={{ fontSize: 10, color: WATCH.textDim, marginLeft: 8 }}>slide to silence</div>
      </div>
    </ScreenCenter>
  );
}

// ─── 19. WatchHistory ───────────────────────────────────────────────────────
function S19_History({ onPick }) {
  const entries = [
    { when: 'Today, 8:14',  states: ['red','orange','soft'],   label: 'H · M · S' },
    { when: 'Yesterday',    states: ['red','red'],             label: '2× Hard',  empty: 1 },
    { when: 'Mon · 7:40',   states: ['orange','orange','orange'], label: '3× Med' },
    { when: 'Sun · 9:02',   states: ['soft'],                  label: '1× Soft',  empty: 2 },
  ];
  const c = (s) => s === 'red' ? WATCH.red : s === 'orange' ? WATCH.orange : s === 'soft' ? WATCH.yellow : 'rgba(255,255,255,0.18)';
  return (
    <>
      <div style={{
        position: 'absolute', top: 10, left: 0, right: 0,
        textAlign: 'center', fontSize: 12, fontWeight: 700,
      }}>Recent</div>
      <div style={{
        position: 'absolute', top: 34, bottom: 8, left: 8, right: 8,
        overflow: 'hidden',
      }}>
        {entries.slice(0, 4).map((e, i) => (
          <div key={i} onClick={onPick} style={{
            padding: '8px 10px', marginBottom: 4,
            background: i === 0 ? 'rgba(255,59,48,0.15)' : 'rgba(255,255,255,0.05)',
            borderRadius: 10, display: 'flex', alignItems: 'center', gap: 8,
            cursor: onPick ? 'pointer' : 'default',
          }}>
            <div style={{ display: 'flex', gap: 2 }}>
              {e.states.map((s, j) => (
                <div key={j} style={{ width: 8, height: 12, borderRadius: 2, border: `1.5px solid ${c(s)}` }} />
              ))}
              {e.empty && [...Array(e.empty)].map((_, j) => (
                <div key={'e'+j} style={{ width: 8, height: 12, borderRadius: 2, border: `1.5px solid rgba(255,255,255,0.15)` }} />
              ))}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 11, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.label}</div>
              <div style={{ fontSize: 9, color: WATCH.textDim }}>{e.when}</div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

// ─── 20. WatchSettings ──────────────────────────────────────────────────────
function S20_Settings() {
  const [haptic, setHaptic] = useState(true);
  const [chime, setChime] = useState(true);
  const [autoStart, setAutoStart] = useState(false);
  const rows = [
    { label: 'Haptics',     value: haptic,    set: setHaptic },
    { label: 'Chime',       value: chime,     set: setChime },
    { label: 'Auto-start',  value: autoStart, set: setAutoStart },
  ];
  return (
    <>
      <div style={{
        position: 'absolute', top: 10, left: 0, right: 0,
        textAlign: 'center', fontSize: 12, fontWeight: 700,
      }}>Settings</div>
      <div style={{
        position: 'absolute', top: 34, bottom: 8, left: 8, right: 8,
      }}>
        {rows.map((r, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            padding: '8px 10px', marginBottom: 4,
            background: 'rgba(255,255,255,0.05)', borderRadius: 10,
          }}>
            <span style={{ fontSize: 12, fontWeight: 500 }}>{r.label}</span>
            <div onClick={(e) => { e.stopPropagation(); r.set(!r.value); }} style={{
              width: 30, height: 18, borderRadius: 9,
              background: r.value ? WATCH.green : 'rgba(255,255,255,0.2)',
              position: 'relative', transition: 'background .15s', cursor: 'pointer',
            }}>
              <div style={{
                position: 'absolute', top: 2, left: r.value ? 14 : 2,
                width: 14, height: 14, borderRadius: '50%', background: '#fff',
                transition: 'left .15s',
              }} />
            </div>
          </div>
        ))}
        <div style={{ fontSize: 9, color: WATCH.textMute, textAlign: 'center', marginTop: 8 }}>
          Divisé · v1.4.2
        </div>
      </div>
    </>
  );
}

// ─── Keyframes for animated screens ─────────────────────────────────────────
if (typeof document !== 'undefined' && !document.getElementById('divise-kf')) {
  const s = document.createElement('style');
  s.id = 'divise-kf';
  s.textContent = `
    @keyframes divisePulse { 0%{opacity:.6;transform:scale(.8)} 100%{opacity:0;transform:scale(2)} }
    @keyframes diviseBoil  { 0%{transform:translateY(0) scaleY(1)} 100%{transform:translateY(-2px) scaleY(1.05)} }
  `;
  document.head.appendChild(s);
}

Object.assign(window, {
  Ring, TimerRing, CookerGlyph, ScreenCenter, PillBtn, IconBtn,
  HARDNESS,
  S01_Home, S02_Splash, S03_Pairing, S04_Connected,
  S05_WaterLow, S06_WaterOk, S_Presets, S07_Compartment,
  S08_Hardness1, S09_Hardness2, S10_Hardness3, S11_Summary,
  S12_Start, S13_Preheat, S14_Running, S15_Paused, S16_CancelConfirm,
  S17_Notification, S18_Done, S19_History, S20_Settings,
});
