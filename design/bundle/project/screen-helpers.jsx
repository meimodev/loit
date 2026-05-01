// Screen helpers — compact Phone frame variant for the screens doc

function PhoneS({children, theme='light', label, caption}) {
  const c = theme === 'dark' ? window.TD : window.T;
  return (
    <div style={{display:'flex', flexDirection:'column', alignItems:'center', gap:10}}>
      <div style={{
        width:320, height:700, borderRadius:36, background:c.canvas, overflow:'hidden',
        border:`1px solid ${theme==='dark'?'#2E3230':'#D4D4CE'}`,
        boxShadow:'0 6px 20px rgba(17,22,19,0.09)',
        position:'relative', fontFamily:window.FONT, flexShrink:0
      }}>
        <div style={{height:28, display:'flex', justifyContent:'space-between', alignItems:'center', padding:'0 18px',
          fontSize:12, fontWeight:600, color:c.primary, position:'relative', zIndex:2}}>
          <span>9:41</span>
          <span style={{display:'flex', gap:4, alignItems:'center'}}>
            <Ico d={icons.wifi} size={12}/>
          </span>
        </div>
        <div style={{height:672, overflow:'hidden', position:'relative'}}>{children}</div>
      </div>
      {label && (
        <div style={{textAlign:'center', maxWidth:320}}>
          <div style={{fontSize:13, color:window.T.primary, fontFamily:window.FONT, fontWeight:600}}>{label}</div>
          {caption && <div style={{fontSize:11, color:window.T.tertiary, fontFamily:window.FONT, marginTop:3, lineHeight:'15px'}}>{caption}</div>}
        </div>
      )}
    </div>
  );
}

// ── Bottom tab bar — flat 4-tab, icon over label, no center notch.
// Layout extracted from money-tracker reference; LOIT brand + tokens applied.
function TabBar({active='home', tabs, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  // Defaults match LOIT IA but layout follows reference: 4 flat tabs
  const list = tabs || [
    ['home','Home','home'],
    ['tx','Transactions','receipt'],
    ['rooms','Rooms','users'],
    ['more','More','more'],
  ];
  return (
    <div style={{position:'absolute', bottom:0, left:0, right:0, height:72, background:c.surface,
      borderTop:`1px solid ${c.bSubtle}`, display:'flex', paddingBottom:10}}>
      {list.map(([id, name, ico]) => {
        const isActive = id===active;
        return (
          <div key={id} style={{flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:4}}>
            <div style={{color: isActive?c.brand:c.tertiary}}><Ico d={icons[ico]} size={22}/></div>
            <div style={{fontSize:10, fontWeight: isActive?700:600, color: isActive?c.brand:c.tertiary, letterSpacing:0.2}}>{name}</div>
          </div>
        );
      })}
    </div>
  );
}

// ── Standard app bar (single title)
function AppBar({title, leading, trailing, subtitle, theme='light', accent}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{padding:'6px 8px 12px', background:c.surface, borderBottom:`1px solid ${c.bSubtle}`, fontFamily:window.FONT}}>
      <div style={{height:44, display:'flex', alignItems:'center'}}>
        {leading || <div style={{width:40}}/>}
        <div style={{flex:1, display:'flex', alignItems:'center', gap:8, paddingLeft:4}}>
          {accent && <div style={{width:8, height:8, borderRadius:'50%', background:accent}}/>}
          <div style={{fontSize:17, fontWeight:600, color:c.primary, letterSpacing:-0.15}}>{title}</div>
        </div>
        {trailing || <div style={{width:40}}/>}
      </div>
      {subtitle && <div style={{padding:'0 12px', fontSize:12, color:c.secondary}}>{subtitle}</div>}
    </div>
  );
}

// ── App bar v2 — month-navigator variant w/ multiple trailing icons
//    Layout from references: ◄ Jan 2026 ► ........... ★ ⌕ ⚙
function AppBarMonth({label, leading, actions=[], theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{padding:'4px 4px 8px', background:c.surface, borderBottom:`1px solid ${c.bSubtle}`, fontFamily:window.FONT}}>
      <div style={{height:44, display:'flex', alignItems:'center'}}>
        {leading || <BackBtn theme={theme}/>}
        <div style={{flex:1, display:'flex', alignItems:'center', gap:2}}>
          <button style={{width:32, height:32, borderRadius:8, background:'transparent', border:'none', color:c.primary, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.chevL} size={18}/></button>
          <div style={{fontSize:15, fontWeight:600, color:c.primary, letterSpacing:-0.1, padding:'0 4px'}}>{label}</div>
          <button style={{width:32, height:32, borderRadius:8, background:'transparent', border:'none', color:c.primary, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.chevR} size={18}/></button>
        </div>
        <div style={{display:'flex', gap:0}}>
          {actions.map((a, i) => (
            <button key={i} style={{width:38, height:38, borderRadius:'50%', background:'transparent', border:'none', color:c.primary, display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
              <Ico d={typeof a==='string'?icons[a]:a} size={20}/>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── Underline tab strip — Daily / Calendar / Monthly / Total / Note
function TabStrip({tabs, active=0, theme='light', dense}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{display:'flex', background:c.surface, borderBottom:`1px solid ${c.bSubtle}`,
      padding: dense?'0 4px':'0 8px', overflowX:'auto', fontFamily:window.FONT}}>
      {tabs.map((t, i) => {
        const isActive = i===active;
        return (
          <div key={t} style={{position:'relative', padding:'12px 14px', fontSize:13, fontWeight: isActive?700:500,
            color: isActive?c.primary:c.tertiary, letterSpacing:0.2, whiteSpace:'nowrap'}}>
            {t}
            {isActive && <div style={{position:'absolute', left:'14%', right:'14%', bottom:-1, height:2.5, background:c.brand, borderRadius:'2px 2px 0 0'}}/>}
          </div>
        );
      })}
    </div>
  );
}

// ── 3-column stat header — Income / Expenses / Total (or Assets / Liabilities / Total)
//    Layout extracted from references: thin row with label above value, subtle dividers
function StatTriple({stats, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{display:'flex', background:c.surface, borderBottom:`1px solid ${c.bSubtle}`, fontFamily:window.FONT}}>
      {stats.map(([label, value, color], i) => (
        <div key={label} style={{flex:1, padding:'10px 8px', textAlign:'center',
          borderLeft: i>0?`1px solid ${c.bSubtle}`:'none'}}>
          <div style={{fontSize:11, color:c.secondary, letterSpacing:0.3}}>{label}</div>
          <div style={{fontSize:15, fontWeight:600, color:color||c.primary, marginTop:3,
            fontVariantNumeric:'tabular-nums', letterSpacing:-0.1}}>{value}</div>
        </div>
      ))}
    </div>
  );
}

// ── Day-section header row — big day + chip + per-day totals
//    The signature "heavy divider" from the reference Daily transactions screen
function DayHeader({day, weekday, weekdayColor, dateSub, income, expense, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{display:'flex', alignItems:'center', padding:'12px 14px', background:c.muted,
      borderTop:`1px solid ${c.bSubtle}`, borderBottom:`1px solid ${c.bSubtle}`, gap:10, fontFamily:window.FONT}}>
      <div style={{fontSize:22, fontWeight:600, color:c.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.4, minWidth:24, textAlign:'center'}}>{day}</div>
      <div style={{padding:'2px 6px', background:weekdayColor||c.brand, color:'#fff', fontSize:10, fontWeight:700, borderRadius:4, letterSpacing:0.4, textTransform:'uppercase'}}>{weekday}</div>
      <div style={{fontSize:11, color:c.tertiary, fontFamily:window.MONO}}>{dateSub}</div>
      <div style={{flex:1}}/>
      {income && <div style={{fontSize:13, fontWeight:600, color:'#3E7AC5', fontVariantNumeric:'tabular-nums'}}>{income}</div>}
      {expense && <div style={{fontSize:13, fontWeight:600, color:'#C5443E', fontVariantNumeric:'tabular-nums', marginLeft:14}}>{expense}</div>}
    </div>
  );
}

// ── Edge-to-edge horizontal-rule list row (Accounts-style). Label left, value right.
function LineRow({label, value, valueColor, leading, sub, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{display:'flex', alignItems:'center', padding:'14px 16px',
      borderBottom:`1px solid ${c.bSubtle}`, gap:12, fontFamily:window.FONT, background:c.surface}}>
      {leading}
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:14, color:c.primary, fontWeight:500}}>{label}</div>
        {sub && <div style={{fontSize:11, color:c.tertiary, marginTop:2}}>{sub}</div>}
      </div>
      <div style={{fontSize:14, fontWeight:600, color:valueColor||c.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.1}}>{value}</div>
    </div>
  );
}

// ── Subtle group label row ("Accounts", "Loan", "Investments")
function GroupLabel({children, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{padding:'14px 16px 8px', fontSize:12, fontWeight:600, color:c.tertiary, fontFamily:window.FONT,
      letterSpacing:0.4, background:c.canvas, borderTop:`1px solid ${c.bSubtle}`, marginTop:6}}>
      {children}
    </div>
  );
}

// ── Compact tx line row — square cat icon (with cat label under) · merchant + account · amount
//    Edge-to-edge, no card; layout matches reference Daily list
function TxLine({cat, merchant, account, amount, amountColor, isIncome, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  const tint = window.CAT_TINT[cat] || c.tertiary;
  const ic = window.CAT_ICON[cat] || 'more';
  return (
    <div style={{display:'flex', alignItems:'center', padding:'12px 14px', gap:12,
      borderBottom:`1px solid ${c.bSubtle}`, background:c.surface, fontFamily:window.FONT, minHeight:60}}>
      <div style={{width:44, display:'flex', flexDirection:'column', alignItems:'center', flexShrink:0}}>
        <div style={{width:36, height:36, borderRadius:8, background:tint+'24', color:tint,
          display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
          <Ico d={icons[ic]} size={18}/>
        </div>
        <div style={{fontSize:9, color:c.tertiary, marginTop:3, fontWeight:500, lineHeight:'10px', textAlign:'center', maxWidth:50, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{cat}</div>
      </div>
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:13.5, color:c.primary, fontWeight:500, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{merchant}</div>
        {account && <div style={{fontSize:11, color:c.tertiary, marginTop:2}}>{account}</div>}
      </div>
      <div style={{fontSize:14, fontWeight:600, color: amountColor || (isIncome?'#3E7AC5':'#C5443E'),
        fontVariantNumeric:'tabular-nums', letterSpacing:-0.1, flexShrink:0}}>
        {amount}
      </div>
    </div>
  );
}

// ── FAB stack — primary FAB + smaller secondary FAB above
//    Position: bottom-right, sits above the bottom tab bar
function FabStack({onPrimary, onSecondary, primaryIcon='plus', secondaryIcon='receipt', theme='light', primaryColor}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{position:'absolute', right:14, bottom:84, display:'flex', flexDirection:'column', alignItems:'center', gap:10}}>
      <button style={{width:42, height:42, borderRadius:'50%', background:c.surface, border:`1px solid ${c.bSubtle}`,
        boxShadow:'0 2px 8px rgba(17,22,19,0.12)', display:'inline-flex', alignItems:'center', justifyContent:'center', color:c.primary}}>
        <Ico d={icons[secondaryIcon]} size={18}/>
      </button>
      <button style={{width:54, height:54, borderRadius:'50%',
        background: primaryColor || c.accent, color:'#fff', border:'none',
        boxShadow:'0 4px 14px rgba(232,146,47,0.35)', display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
        <Ico d={icons[primaryIcon]} size={26} stroke="#fff" sw={2.5}/>
      </button>
    </div>
  );
}

function BackBtn({theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return <button style={{width:40, height:40, borderRadius:'50%', background:'transparent', border:'none', display:'inline-flex', alignItems:'center', justifyContent:'center', color:c.primary}}><Ico d={icons.chevL} size={22}/></button>;
}
function CloseBtn({theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return <button style={{width:40, height:40, borderRadius:'50%', background:'transparent', border:'none', display:'inline-flex', alignItems:'center', justifyContent:'center', color:c.primary}}><Ico d={icons.x} size={22}/></button>;
}
function IconBtn({d, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return <button style={{width:40, height:40, borderRadius:'50%', background:'transparent', border:'none', display:'inline-flex', alignItems:'center', justifyContent:'center', color:c.primary}}><Ico d={d} size={22}/></button>;
}

// Section header on artboards
function ArtboardHeader({num, title, subtitle}) {
  return (
    <div style={{padding:'20px 28px', borderBottom:`1px solid ${T.bSubtle}`, background:T.surface, fontFamily:FONT}}>
      <div style={{fontSize:11, letterSpacing:1, textTransform:'uppercase', color:T.brand, fontWeight:600, fontFamily:MONO}}>{num}</div>
      <div style={{fontSize:22, fontWeight:600, color:T.primary, letterSpacing:-0.2, marginTop:4}}>{title}</div>
      {subtitle && <div style={{fontSize:13, color:T.secondary, marginTop:4, maxWidth:900, lineHeight:'18px'}}>{subtitle}</div>}
    </div>
  );
}

function ScreensGrid({children}) {
  return <div style={{padding:'24px 28px 36px', display:'flex', gap:28, flexWrap:'wrap', background:T.canvas}}>{children}</div>;
}

// Body padding helper — accounts for the 72px tab bar + safe area
const TAB_PAD = 88;

Object.assign(window, {PhoneS, TabBar, AppBar, AppBarMonth, TabStrip, StatTriple,
  DayHeader, LineRow, GroupLabel, TxLine, FabStack,
  BackBtn, CloseBtn, IconBtn, ArtboardHeader, ScreensGrid, TAB_PAD});
