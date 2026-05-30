// Top-level layout — header, interactive prototype, then the gallery of all
// 20 screens grouped into 5 sections. Dark presentation matches the
// reference image style.

const sections = [
  {
    id: 'onboarding', label: '01–04 · Onboarding & Pairing',
    sub: 'First-run setup. The user opens the app on their watch and pairs with the cooker.',
    steps: [
      { id: 'home',      title: '01 · Watch home',     comp: 'S01_Home',      tag: 'NEW' },
      { id: 'splash',    title: '02 · Brand splash',   comp: 'S02_Splash',    tag: 'EXISTING' },
      { id: 'pairing',   title: '03 · Pairing',        comp: 'S03_Pairing',   tag: 'NEW' },
      { id: 'connected', title: '04 · Connected',      comp: 'S04_Connected', tag: 'NEW' },
    ],
  },
  {
    id: 'precook', label: '05–08 · Pre-cook & preset start',
    sub: 'Su seviyesi kontrolü, ardından hazır preset’le hızlı başlatma veya kompartman seçimine geçiş.',
    steps: [
      { id: 'water_low',   title: '05 · Water low',      comp: 'S05_WaterLow',   tag: 'NEW' },
      { id: 'water_ok',    title: '06 · Water OK',       comp: 'S06_WaterOk',    tag: 'NEW' },
      { id: 'presets',     title: '07 · Presets',        comp: 'S_Presets',      tag: 'NEW' },
      { id: 'compartment', title: '08 · Compartments',   comp: 'S07_Compartment',tag: 'EXISTING' },
    ],
  },
  {
    id: 'setup', label: '09–12 · Per-slot hardness',
    sub: 'Preset yerine custom seildiyse her kompartmana ayrı sertlik. Sonunda özet.',
    steps: [
      { id: 'hardness_1', title: '09 · Slot 1 · Hard',   comp: 'S08_Hardness1', tag: 'NEW' },
      { id: 'hardness_2', title: '10 · Slot 2 · Medium', comp: 'S09_Hardness2', tag: 'EXISTING' },
      { id: 'hardness_3', title: '11 · Slot 3 · Soft',   comp: 'S10_Hardness3', tag: 'NEW' },
      { id: 'summary',    title: '12 · Summary',         comp: 'S11_Summary',   tag: 'NEW' },
    ],
  },
  {
    id: 'cooking', label: '13–17 · Cooking',
    sub: 'Timer is set, water heats, eggs cook. Controls for pause and stop.',
    steps: [
      { id: 'start',   title: '13 · Start',         comp: 'S12_Start',         tag: 'EXISTING' },
      { id: 'preheat', title: '14 · Preheating',    comp: 'S13_Preheat',       tag: 'NEW' },
      { id: 'running', title: '15 · Cooking',       comp: 'S14_Running',       tag: 'EXISTING' },
      { id: 'paused',  title: '16 · Paused',        comp: 'S15_Paused',        tag: 'NEW' },
      { id: 'cancel',  title: '17 · Cancel?',       comp: 'S16_CancelConfirm', tag: 'NEW' },
    ],
  },
  {
    id: 'done', label: '18–21 · Notification, done & more',
    sub: 'Done state, push-notification on the watch, plus history and settings.',
    steps: [
      { id: 'notif',    title: '18 · Notification', comp: 'S17_Notification', tag: 'NEW' },
      { id: 'done_s',   title: '19 · Done',         comp: 'S18_Done',         tag: 'EXISTING' },
      { id: 'history',  title: '20 · History',      comp: 'S19_History',      tag: 'NEW' },
      { id: 'settings', title: '21 · Settings',     comp: 'S20_Settings',     tag: 'NEW' },
    ],
  },
];

function SectionHeader({ idx, label, sub }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', gap: 14,
      marginBottom: 18, paddingLeft: 4,
    }}>
      <div style={{ fontSize: 13, color: WATCH.textMute, fontFamily: WATCH.font, fontWeight: 600 }}>§ {idx + 1}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: WATCH.font, fontSize: 18, fontWeight: 600, color: '#fff' }}>{label}</div>
        <div style={{ fontFamily: WATCH.font, fontSize: 13, color: WATCH.textDim, marginTop: 2, maxWidth: 760 }}>{sub}</div>
      </div>
    </div>
  );
}

function GalleryCard({ step }) {
  const Comp = window[step.comp];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start' }}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10,
        fontFamily: WATCH.font,
      }}>
        <span style={{ fontSize: 12, color: WATCH.textDim, letterSpacing: 0.2 }}>{step.title}</span>
        {step.tag === 'NEW' && (
          <span style={{
            fontSize: 9, fontWeight: 700, letterSpacing: 0.6,
            background: 'rgba(255,59,48,0.18)', color: WATCH.red,
            padding: '2px 6px', borderRadius: 4,
          }}>NEW</span>
        )}
        {step.tag === 'EXISTING' && (
          <span style={{
            fontSize: 9, fontWeight: 700, letterSpacing: 0.6,
            background: 'rgba(255,255,255,0.06)', color: WATCH.textDim,
            padding: '2px 6px', borderRadius: 4,
          }}>EXISTING</span>
        )}
      </div>
      <WatchFrame width={240} height={290} screenLabel={step.title}>
        <Comp />
      </WatchFrame>
    </div>
  );
}

function WatchCanvas() {
  return (
    <div style={{
      minHeight: '100vh', background: WATCH.pageBg,
      padding: '40px 48px 80px',
      fontFamily: WATCH.font, color: '#fff',
    }}>
      {/* page header */}
      <div style={{ marginBottom: 36, maxWidth: 900 }}>
        <div style={{
          fontSize: 11, letterSpacing: 0.6, color: WATCH.textMute, fontWeight: 600,
          textTransform: 'uppercase', marginBottom: 8,
        }}>VESTEL Divisé · Apple Watch · Flow exploration</div>
        <div style={{ fontSize: 30, fontWeight: 600, lineHeight: 1.1, marginBottom: 8 }}>
          6 → 21 ekran: yumurta pişirme akışı genişletildi
        </div>
        <div style={{ fontSize: 15, color: WATCH.textDim, lineHeight: 1.5, maxWidth: 720 }}>
          Mevcut 6 ekran (splash, slot seçimi, sertlik, start, çalışıyor, done) korunarak araya{' '}
          <span style={{ color: WATCH.red, fontWeight: 600 }}>15 yeni ekran</span>{' '}
          eklendi: cihaz eşleşmesi, su kontrolü, <span style={{ color: WATCH.red, fontWeight: 600 }}>hazır preset’ler</span>,
          slot başı sertlik, önizleme, ısınma, duraklatma, iptal onayı, bildirim, geçmiş ve ayarlar.
          Etkileşimli prototip aşağıda; her ekran ayrıca galeride.
        </div>
      </div>

      {/* interactive prototype */}
      <div style={{ marginBottom: 56 }}>
        <div style={{
          fontSize: 11, letterSpacing: 0.6, color: WATCH.textMute, fontWeight: 600,
          textTransform: 'uppercase', marginBottom: 12,
        }}>Interactive prototype</div>
        <WatchPrototype />
      </div>

      {/* sections */}
      {sections.map((s, i) => (
        <div key={s.id} style={{ marginBottom: 56 }}>
          <SectionHeader idx={i} label={s.label} sub={s.sub} />
          <div style={{
            display: 'flex', flexWrap: 'wrap', gap: 28,
            paddingBottom: 8,
          }}>
            {s.steps.map(step => <GalleryCard key={step.id} step={step} />)}
          </div>
        </div>
      ))}

      {/* footer note */}
      <div style={{
        fontSize: 12, color: WATCH.textMute, marginTop: 20,
        paddingTop: 24, borderTop: '1px solid rgba(255,255,255,0.06)',
        maxWidth: 760, lineHeight: 1.5,
      }}>
        Renkler: <span style={{ color: WATCH.red }}>kırmızı</span> = aktif/seçili,{' '}
        <span style={{ color: WATCH.orange }}>turuncu</span> = ikincil/zamanlayıcı,{' '}
        <span style={{ color: WATCH.green }}>yeşil</span> = onay,{' '}
        <span style={{ color: WATCH.blue }}>mavi</span> = su.
        Tipografi SF (sistem), arkaplan #1a1a1c.
      </div>
    </div>
  );
}

Object.assign(window, { WatchCanvas });
