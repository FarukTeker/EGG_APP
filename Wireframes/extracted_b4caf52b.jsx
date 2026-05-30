// WatchFrame — rounded-square Apple-Watch-ish stage that matches the
// reference (dark frame on darker page, no visible bezel, just a rounded
// rect containing the screen content).
const WATCH = {
  bg: '#1a1a1c',            // watch face background
  pageBg: '#0a0a0a',        // surrounding canvas background
  cardBg: '#262628',        // section card surface
  border: 'rgba(255,255,255,0.06)',
  text: '#ffffff',
  textDim: 'rgba(255,255,255,0.55)',
  textMute: 'rgba(255,255,255,0.32)',
  red: '#FF3B30',
  redDim: '#C62A22',
  orange: '#FF9500',
  yellow: '#FFD60A',
  green: '#34C759',
  blue: '#0A84FF',
  ringTrack: 'rgba(255,255,255,0.14)',
  label: 'rgba(255,255,255,0.45)',
  font: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", system-ui, sans-serif',
  fontDisplay: '-apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif',
};

function WatchFrame({ children, width = 240, height = 290, bg, style, onClick, screenLabel }) {
  return (
    <div
      data-screen-label={screenLabel}
      onClick={onClick}
      style={{
        width, height,
        background: bg || WATCH.bg,
        borderRadius: Math.round(width * 0.16),
        position: 'relative',
        overflow: 'hidden',
        color: WATCH.text,
        fontFamily: WATCH.font,
        boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.04)',
        cursor: onClick ? 'pointer' : 'default',
        userSelect: 'none',
        ...style,
      }}>
      {children}
    </div>
  );
}

// Status-bar style time indicator (top of each Apple Watch screen).
function WatchTime({ time = '10:24', color }) {
  return (
    <div style={{
      position: 'absolute', top: 10, right: 18,
      fontSize: 13, fontWeight: 600, letterSpacing: 0.2,
      color: color || WATCH.orange,
      fontFamily: WATCH.font,
    }}>{time}</div>
  );
}

// Caption shown above each watch frame ("Watch" by default, but a screen
// name reads better in a 20-screen exploration).
function WatchCaption({ children }) {
  return (
    <div style={{
      fontFamily: WATCH.font,
      fontSize: 13,
      color: WATCH.label,
      letterSpacing: 0.1,
      marginBottom: 10,
      paddingLeft: 4,
    }}>{children}</div>
  );
}

Object.assign(window, { WatchFrame, WatchTime, WatchCaption, WATCH });
