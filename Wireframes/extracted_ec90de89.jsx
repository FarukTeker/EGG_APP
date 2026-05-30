// Interactive prototype: one watch frame, threaded through the 20-screen
// state machine. The user can advance via tap targets within each screen
// (Start, Continue, etc.) OR with prev/next arrows just outside the frame
// for free roaming. Reset jumps back to screen 1.

const protoSteps = [
  { id: 'home',          comp: 'S01_Home',          title: '01 · Watch home' },
  { id: 'splash',        comp: 'S02_Splash',        title: '02 · Brand splash' },
  { id: 'pairing',       comp: 'S03_Pairing',       title: '03 · Pairing' },
  { id: 'connected',     comp: 'S04_Connected',     title: '04 · Connected' },
  { id: 'water_low',     comp: 'S05_WaterLow',      title: '05 · Water low' },
  { id: 'water_ok',      comp: 'S06_WaterOk',       title: '06 · Water OK' },
  { id: 'presets',       comp: 'S_Presets',         title: '07 · Presets' },
  { id: 'compartment',   comp: 'S07_Compartment',   title: '08 · Slots in use' },
  { id: 'hardness_1',    comp: 'S08_Hardness1',     title: '09 · Slot 1 · Hard' },
  { id: 'hardness_2',    comp: 'S09_Hardness2',     title: '10 · Slot 2 · Medium' },
  { id: 'hardness_3',    comp: 'S10_Hardness3',     title: '11 · Slot 3 · Soft' },
  { id: 'summary',       comp: 'S11_Summary',       title: '12 · Summary' },
  { id: 'start',         comp: 'S12_Start',         title: '13 · Start' },
  { id: 'preheat',       comp: 'S13_Preheat',       title: '14 · Preheating' },
  { id: 'running',       comp: 'S14_Running',       title: '15 · Cooking' },
  { id: 'paused',        comp: 'S15_Paused',        title: '16 · Paused' },
  { id: 'cancel',        comp: 'S16_CancelConfirm', title: '17 · Cancel?' },
  { id: 'notification',  comp: 'S17_Notification',  title: '18 · Notification' },
  { id: 'done',          comp: 'S18_Done',          title: '19 · Done' },
  { id: 'history',       comp: 'S19_History',       title: '20 · History' },
  { id: 'settings',      comp: 'S20_Settings',      title: '21 · Settings' },
];

// What "natural progression" means inside each screen. The component
// receives onX handlers (onStart, onContinue, etc.) and advances the
// prototype's step index.
const naturalNext = {
  home: 'splash', splash: 'pairing', pairing: 'connected', connected: 'water_low',
  water_low: 'water_ok', water_ok: 'presets',
  presets: 'summary',          // default preset takes you straight to summary
  compartment: 'hardness_1',
  hardness_1: 'hardness_2', hardness_2: 'hardness_3', hardness_3: 'summary',
  summary: 'start', start: 'preheat', preheat: 'running',
  running: 'paused', paused: 'running',
  cancel: 'home',
  notification: 'running',
  done: 'history', history: 'settings', settings: 'home',
};

function WatchPrototype() {
  const [stepId, setStepId] = useState('home');
  const [autoAdvanceCancel, setAutoAdvanceCancel] = useState(false);
  const step = protoSteps.find(s => s.id === stepId);
  const idx = protoSteps.findIndex(s => s.id === stepId);
  const ScreenComp = window[step.comp];

  const goNext = () => setStepId(protoSteps[(idx + 1) % protoSteps.length].id);
  const goPrev = () => setStepId(protoSteps[(idx - 1 + protoSteps.length) % protoSteps.length].id);
  const goNatural = () => setStepId(naturalNext[stepId] || protoSteps[(idx + 1) % protoSteps.length].id);
  const goTo = (id) => setStepId(id);

  // Per-screen handlers — most just advance; running→pause→running needs
  // distinct buttons; cancel-confirm has its own keep/stop split.
  const handlers = {
    onLaunch: goNatural, onContinue: goNatural, onStart: goNatural, onDone: goNatural,
    onRefill: () => goTo('water_ok'),
    onEdit: () => goTo('compartment'),
    onOpen: () => goTo('running'),
    onDismiss: () => goTo('home'),
    onPick: () => goTo('start'),
    onStop: stepId === 'paused' ? () => goTo('cancel') : () => goTo('cancel'),
    onPause: () => goTo('paused'),
    onResume: () => goTo('running'),
    onCancel: stepId === 'cancel' ? () => goTo('running') : goNext,  // cancel-confirm's "Keep"
    onConfirm: () => goTo('home'),
    // preset screen — "Use" jumps over the manual flow to summary;
    // "Custom…" drops into the per-slot configuration.
    onUsePreset: () => goTo('summary'),
    onCustom: () => goTo('compartment'),
    onSelect: () => {},  // preset selection (no-op; default already highlighted)
  };

  return (
    <div style={{
      background: WATCH.cardBg, borderRadius: 28, padding: '28px 32px 24px',
      display: 'flex', alignItems: 'center', gap: 32,
      boxShadow: '0 4px 24px rgba(0,0,0,0.4)',
    }}>
      {/* prev / next pillars */}
      <button onClick={goPrev} style={protoArrowStyle()}>‹</button>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
        <div style={{
          fontFamily: WATCH.font, fontSize: 12, color: WATCH.textDim, letterSpacing: 0.3,
          textTransform: 'uppercase',
        }}>{step.title}</div>
        <WatchFrame width={224} height={272} screenLabel={step.title}>
          <ScreenComp {...handlers} />
        </WatchFrame>
        {/* step pip indicator */}
        <div style={{ display: 'flex', gap: 4, marginTop: 4, maxWidth: 224, flexWrap: 'wrap', justifyContent: 'center' }}>
          {protoSteps.map((s, i) => (
            <button key={s.id} onClick={() => setStepId(s.id)}
              title={s.title}
              style={{
                width: 8, height: 8, borderRadius: '50%', padding: 0,
                background: i === idx ? WATCH.red : i < idx ? 'rgba(255,255,255,0.32)' : 'rgba(255,255,255,0.12)',
                border: 'none', cursor: 'pointer',
              }} />
          ))}
        </div>
      </div>

      <button onClick={goNext} style={protoArrowStyle()}>›</button>

      {/* side rail */}
      <div style={{
        display: 'flex', flexDirection: 'column', gap: 10,
        fontFamily: WATCH.font, color: WATCH.text,
      }}>
        <div style={{ fontSize: 12, color: WATCH.textDim, letterSpacing: 0.3, textTransform: 'uppercase' }}>Prototype</div>
        <div style={{ fontSize: 20, fontWeight: 600 }}>Step {idx + 1} of 21</div>
        <div style={{ fontSize: 12, color: WATCH.textDim, lineHeight: 1.5, maxWidth: 220 }}>
          Tap targets inside the screen (Start, Continue, Resume…) advance the flow.
          Arrows step through every screen in order.
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 6, flexWrap: 'wrap' }}>
          <button onClick={() => setStepId('home')} style={chipStyle()}>Reset</button>
          <button onClick={() => setStepId('running')} style={chipStyle()}>Jump to cooking</button>
          <button onClick={() => setStepId('done')} style={chipStyle()}>Jump to done</button>
        </div>
      </div>
    </div>
  );
}

function protoArrowStyle() {
  return {
    width: 44, height: 44, borderRadius: '50%',
    background: 'rgba(255,255,255,0.06)', color: '#fff',
    border: '1px solid rgba(255,255,255,0.1)',
    fontSize: 26, lineHeight: 1, paddingBottom: 4,
    cursor: 'pointer', fontFamily: WATCH.font,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
}
function chipStyle() {
  return {
    background: 'rgba(255,255,255,0.08)', color: '#fff', border: 'none',
    height: 26, padding: '0 12px', borderRadius: 13,
    fontFamily: WATCH.font, fontSize: 12, fontWeight: 500, cursor: 'pointer',
  };
}

Object.assign(window, { WatchPrototype, protoSteps });
