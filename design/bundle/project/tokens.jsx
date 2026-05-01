// LOIT Design tokens — mirrors the canonical spec

const T = {
  // Neutrals
  n50:'#FAFAF7', n100:'#F3F2ED', n200:'#EAEAE4', n300:'#D4D4CE',
  n400:'#B0B2AC', n500:'#9AA09E', n600:'#74787A', n700:'#5A6160',
  n800:'#2E3230', n900:'#111613',
  // Teal
  teal50:'#E6F4F0', teal100:'#C4E4DB', teal200:'#96CDBE', teal300:'#67B5A0',
  teal400:'#3E9C82', teal500:'#188268', teal600:'#0F6E5C', teal700:'#0A5A4B',
  teal800:'#06463B', teal900:'#033229',
  // Ochre
  ochre50:'#FDF5EA', ochre100:'#FBE7C9', ochre200:'#F8D29A', ochre300:'#F5BC6D',
  ochre400:'#F2A85C', ochre500:'#E8922F', ochre600:'#C77A1E', ochre700:'#9E5F14',
  ochre800:'#76460D', ochre900:'#4E2D06',
  // Status
  green50:'#E8F5EC', green400:'#4FA678', green500:'#2F8F5E', green600:'#227549', green700:'#195B38',
  amber50:'#FDF4E0', amber400:'#E0A93A', amber500:'#D49A2B', amber600:'#A87820', amber700:'#7D5916',
  red50:'#FBEAE9', red400:'#D15C55', red500:'#C5443E', red600:'#9D332E', red700:'#762622',
  blue50:'#E6EEF8', blue400:'#5A8FCE', blue500:'#3E7AC5', blue600:'#2F5E99', blue700:'#22456F',
  // Rooms
  room1:'#0F6E5C', room2:'#F2A85C', room3:'#7A4FBF', room4:'#C5443E',
  room5:'#3E7AC5', room6:'#2F8F5E', room7:'#D47A9B', room8:'#5A6160',
  // semantic light
  canvas:'#FAFAF7', surface:'#FFFFFF', raised:'#FFFFFF', overlay:'#FFFFFF', muted:'#F3F2ED',
  inverse:'#111613',
  primary:'#111613', secondary:'#5A6160', tertiary:'#9AA09E', disabled:'#B0B2AC',
  invText:'#FFFFFF', brand:'#0F6E5C', accent:'#E8922F',
  bSubtle:'#EAEAE4', bDefault:'#D4D4CE', bStrong:'#B0B2AC', bFocus:'#188268', bDanger:'#C5443E',
};

// Dark-mode semantic
const TD = {
  canvas:'#101311', surface:'#181B19', raised:'#1F2321', overlay:'#262A28', muted:'rgba(34,38,36,0.51)',
  inverse:'#FAFAF7',
  primary:'#F2F2EC', secondary:'#B8BCB6', tertiary:'#8A8E88', disabled:'#5A5E58',
  invText:'#111613', brand:'#67B5A0', accent:'#F5BC6D',
  bSubtle:'#2E3230', bDefault:'#3A3E3C', bStrong:'#525652', bFocus:'#67B5A0', bDanger:'#D15C55',
  success:'#4FA678', warning:'#E0A93A', danger:'#D15C55', info:'#5A8FCE',
  successSurf:'#1A2E22', warningSurf:'#2E2414', dangerSurf:'#2E1A18', infoSurf:'#18242E',
};

window.T = T;
window.TD = TD;

// Font stack
const FONT = 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, system-ui, sans-serif';
const MONO = '"JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace';
window.FONT = FONT;
window.MONO = MONO;

// ── tiny icon primitives (lucide-style stroke 1.5) ────────────
function Ico({d, size=20, stroke='currentColor', fill='none', sw=1.75, style}) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={stroke}
      strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style}>
      {d}
    </svg>
  );
}
const icons = {
  utensils: <><path d="M3 2v7a3 3 0 0 0 3 3v10"/><path d="M9 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/></>,
  basket: <><path d="m15 11-1 9"/><path d="m19 11-4-7"/><path d="M2 11h20"/><path d="m3.5 11 1.6 7.4a2 2 0 0 0 2 1.6h9.8a2 2 0 0 0 2-1.6l1.6-7.4"/><path d="M4.5 15.5h15"/><path d="m5 11 4-7"/><path d="m9 11 1 9"/></>,
  car: <><path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/></>,
  bag: <><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/></>,
  ticket: <><path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z"/><path d="M13 5v2"/><path d="M13 17v2"/><path d="M13 11v2"/></>,
  plug: <><path d="M12 22v-5"/><path d="M9 7V2"/><path d="M15 7V2"/><path d="M6 13V8h12v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4Z"/></>,
  heart: <><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></>,
  plane: <><path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/></>,
  more: <><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/></>,
  receipt: <><path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/><path d="M12 17.5v-11"/></>,
  home: <><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></>,
  camera: <><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3Z"/><circle cx="12" cy="13" r="3"/></>,
  users: <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></>,
  settings: <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></>,
  check: <polyline points="20 6 9 17 4 12"/>,
  x: <><path d="M18 6 6 18"/><path d="m6 6 12 12"/></>,
  search: <><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></>,
  chevL: <polyline points="15 18 9 12 15 6"/>,
  chevR: <polyline points="9 18 15 12 9 6"/>,
  plus: <><path d="M12 5v14"/><path d="M5 12h14"/></>,
  arrowUp: <><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></>,
  arrowDown: <><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></>,
  alert: <><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></>,
  info: <><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></>,
  cloud: <path d="M17.5 19a4.5 4.5 0 1 0-1.41-8.78 7 7 0 1 0-12.09 6.28"/>,
  trash: <><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></>,
  edit: <><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1 1-4z"/></>,
  qr: <><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3h-3z"/><path d="M17 17h4v4h-4z"/></>,
  eye: <><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></>,
  wifi: <><path d="M2 8.82a15 15 0 0 1 20 0"/><path d="M5 12.859a10 10 0 0 1 14 0"/><path d="M8.5 16.429a5 5 0 0 1 7 0"/><line x1="12" y1="20" x2="12.01" y2="20"/></>,
  noWifi: <><path d="m1 1 22 22"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/></>,
  paperclip: <path d="M21.44 11.05 12.25 20.24a6 6 0 0 1-8.49-8.49L12.95 2.56a4 4 0 0 1 5.66 5.66L9.41 17.41a2 2 0 0 1-2.83-2.83l8.49-8.48"/>,
  chart: <><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></>,
  filter: <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>,
  star: <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>,
  camera: <><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></>,
  users: <><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></>,
  car: <><path d="M5 17h14"/><path d="M5 11h14l-1.5-4.5a2 2 0 0 0-1.9-1.5H8.4a2 2 0 0 0-1.9 1.5L5 11Z"/><path d="M5 17v3"/><path d="M19 17v3"/><circle cx="8" cy="14" r="1"/><circle cx="16" cy="14" r="1"/></>,
  bag: <><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/></>,
  ticket: <><path d="M3 7v2a3 3 0 0 1 0 6v2c0 1.1.9 2 2 2h14a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2z"/></>,
  plug: <><path d="M9 2v6"/><path d="M15 2v6"/><path d="M6 8h12v4a6 6 0 1 1-12 0z"/><path d="M12 18v4"/></>,
  tag: <><path d="M20.59 13.41 13.42 20.58a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><circle cx="7" cy="7" r="1"/></>,
  globe: <><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></>,
  flag: <><path d="M4 22V4l9 4 7-3v12l-7 3-9-4z"/></>,
};
window.Ico = Ico;
window.icons = icons;
