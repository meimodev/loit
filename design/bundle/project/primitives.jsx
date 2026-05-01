// Shared primitives used across artboards

const loitFont = {fontFamily: window.FONT, color: window.T.primary};

// Screen-title header for artboards
function Header({title, subtitle, theme='light'}) {
  const c = theme === 'dark' ? window.TD : window.T;
  return (
    <div style={{padding:'32px 32px 20px', borderBottom:`1px solid ${c.bSubtle}`}}>
      <div style={{fontSize:13, fontWeight:600, letterSpacing:1.2, textTransform:'uppercase', color:c.brand, marginBottom:8}}>LOIT · Design System</div>
      <div style={{fontSize:32, fontWeight:600, letterSpacing:-0.3, color:c.primary, lineHeight:'36px'}}>{title}</div>
      {subtitle && <div style={{fontSize:15, color:c.secondary, marginTop:8, maxWidth:680, lineHeight:'22px'}}>{subtitle}</div>}
    </div>
  );
}

function SwatchRow({label, hex, token, textOn='dark', note}) {
  return (
    <div style={{display:'flex', alignItems:'center', padding:'10px 0', borderBottom:`1px solid ${window.T.bSubtle}`}}>
      <div style={{width:56, height:40, borderRadius:8, background:hex, border:`1px solid ${window.T.bSubtle}`, flexShrink:0}}/>
      <div style={{marginLeft:14, flex:1}}>
        <div style={{fontSize:13, fontWeight:600, color:window.T.primary, fontFamily:window.FONT}}>{token}</div>
        <div style={{fontSize:12, color:window.T.secondary, fontFamily:window.MONO, marginTop:2}}>{hex}</div>
      </div>
      {note && <div style={{fontSize:11, color:window.T.tertiary, fontFamily:window.FONT}}>{note}</div>}
    </div>
  );
}

function Swatch({hex, name, step, textLight}) {
  return (
    <div style={{flex:1, minWidth:0}}>
      <div style={{height:68, background:hex, borderRadius:8, border:`1px solid ${window.T.bSubtle}`,
        display:'flex', alignItems:'flex-end', padding:8,
        color: textLight?'#fff':window.T.primary, fontFamily:window.MONO, fontSize:11, fontWeight:500}}>
        {step}
      </div>
      <div style={{fontSize:11, color:window.T.secondary, fontFamily:window.MONO, marginTop:4}}>{hex}</div>
    </div>
  );
}

function Section({title, children, note, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{marginBottom:28}}>
      <div style={{fontSize:12, fontWeight:600, letterSpacing:0.6, textTransform:'uppercase', color:c.secondary, fontFamily:window.FONT, marginBottom:10}}>{title}</div>
      {children}
      {note && <div style={{marginTop:8, fontSize:12, color:c.tertiary, fontFamily:window.FONT, lineHeight:'18px', maxWidth:640}}>{note}</div>}
    </div>
  );
}

function Label({children, color}) {
  return <div style={{fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', color:color||window.T.tertiary, fontFamily:window.FONT, marginBottom:10}}>{children}</div>;
}

// Button renderer matching spec
function LoitButton({variant='primary', size='m', label, leading, trailing, disabled, loading, fullWidth, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  const sizes = {s:{h:36,px:12,fs:14}, m:{h:44,px:16,fs:16}, l:{h:52,px:20,fs:16}};
  const sz = sizes[size];
  let bg, fg, border='none';
  if (variant==='primary') { bg=c.brand; fg=c.invText; }
  else if (variant==='secondary') { bg=c.surface; fg=c.brand; border=`1.5px solid ${c.bStrong}`; }
  else if (variant==='tertiary') { bg='transparent'; fg=c.brand; }
  else if (variant==='destructive') { bg=theme==='dark'?TD.dangerSurf:'#FBEAE9'; fg=theme==='dark'?TD.danger:'#9D332E'; }
  else if (variant==='destructive.solid') { bg='#C5443E'; fg=c.invText; }
  else if (variant==='ghost') { bg='transparent'; fg=c.primary; }
  if (disabled) { bg = variant==='primary'?c.bSubtle:bg; fg = c.disabled; }
  return (
    <button disabled={disabled} style={{
      height:sz.h, padding:`0 ${sz.px}px`, borderRadius:12, border, background:bg,
      color:fg, fontSize:sz.fs, fontWeight:600, fontFamily:window.FONT,
      display:'inline-flex', alignItems:'center', gap:8, cursor:disabled?'not-allowed':'pointer',
      width:fullWidth?'100%':undefined, justifyContent:'center',
      opacity:disabled?0.4:1, letterSpacing:-0.1
    }}>
      {loading ? <div style={{width:16,height:16,border:`2px solid ${fg}`, borderTopColor:'transparent', borderRadius:'50%', animation:'loit-spin 1s linear infinite'}}/> :
        <>{leading}{label}{trailing}</>}
    </button>
  );
}

// Chip
function LoitChip({label, selected, variant='default', leading, dismiss, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  let bg, fg, border='none';
  if (variant==='selected' || selected) { bg=c.brand; fg=c.invText; }
  else if (variant==='outline') { bg='transparent'; fg=c.primary; border=`1px solid ${c.bDefault}`; }
  else { bg=c.muted; fg=c.primary; }
  return (
    <span style={{height:32, borderRadius:999, padding:'0 12px', background:bg, color:fg, border,
      display:'inline-flex', alignItems:'center', gap:4, fontSize:12, fontWeight:600, fontFamily:window.FONT, letterSpacing:0.3}}>
      {leading}{label}{dismiss && <span style={{marginLeft:2, opacity:0.75}}><Ico d={icons.x} size={12}/></span>}
    </span>
  );
}

// Input
function LoitInput({label, value, placeholder, error, helper, leading, trailing, state='default', size='m', theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  const sizes = {s:36, m:44, l:52};
  let border = `1px solid ${c.bDefault}`;
  if (state==='focused') border = `2px solid ${c.bFocus}`;
  if (state==='error') border = `2px solid ${c.bDanger}`;
  if (state==='disabled') border = `1px solid ${c.bSubtle}`;
  return (
    <div style={{fontFamily:window.FONT}}>
      {label && <div style={{fontSize:14, fontWeight:600, color:c.primary, marginBottom:6, letterSpacing:0.2}}>{label}</div>}
      <div style={{height:sizes[size], borderRadius:12, border, background:state==='disabled'?c.muted:c.surface,
        display:'flex', alignItems:'center', padding:'0 14px', gap:10}}>
        {leading && <span style={{color:c.secondary}}>{leading}</span>}
        <div style={{flex:1, fontSize:16, color: value?c.primary:c.tertiary}}>
          {value || placeholder}
        </div>
        {trailing && <span style={{color:c.secondary}}>{trailing}</span>}
      </div>
      {error && <div style={{fontSize:12, color:'#C5443E', marginTop:6, fontWeight:500}}>{error}</div>}
      {helper && !error && <div style={{fontSize:12, color:c.secondary, marginTop:6}}>{helper}</div>}
    </div>
  );
}

// Card
function LoitCard({children, raised, style, theme='light', interactive, status}) {
  const c = theme==='dark' ? window.TD : window.T;
  const statusColors = {success:'#2F8F5E', warning:'#D49A2B', danger:'#C5443E', info:'#3E7AC5'};
  return (
    <div style={{
      background:c.surface, borderRadius:16, padding:16,
      border:`1px solid ${c.bSubtle}`,
      boxShadow: raised?'0 1px 2px rgba(17,22,19,0.04)':'none',
      position:'relative', overflow:'hidden',
      ...style
    }}>
      {status && <div style={{position:'absolute', left:0, top:0, bottom:0, width:4, background:statusColors[status]}}/>}
      {children}
    </div>
  );
}

// Avatar
function Avatar({size=40, initials, color='#0F6E5C', theme='light'}) {
  return (
    <div style={{width:size, height:size, borderRadius:'50%', background:color,
      color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center',
      fontSize:size*0.38, fontWeight:600, fontFamily:window.FONT, letterSpacing:0.2,
      border:`1px solid ${window.T.bSubtle}`}}>
      {initials}
    </div>
  );
}

function AvatarStack({members, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  const visible = members.slice(0,4);
  const extra = members.length - 4;
  return (
    <div style={{display:'inline-flex'}}>
      {visible.map((m,i) => (
        <div key={i} style={{marginLeft: i===0?0:-8, border:`2px solid ${c.surface}`, borderRadius:'50%'}}>
          <Avatar size={28} initials={m.initials} color={m.color}/>
        </div>
      ))}
      {extra>0 && (
        <div style={{marginLeft:-8, width:28, height:28, borderRadius:'50%', background:c.muted,
          border:`2px solid ${c.surface}`, display:'flex', alignItems:'center', justifyContent:'center',
          fontSize:11, fontWeight:600, color:c.primary, fontFamily:window.FONT}}>+{extra}</div>
      )}
    </div>
  );
}

// Category icon bubble for rows
const CAT_TINT = {
  Dining:'#F2A85C', Groceries:'#2F8F5E', Transport:'#3E7AC5', Shopping:'#B15FC0',
  Entertainment:'#E06B8A', Utilities:'#5A6160', Health:'#C5443E', Travel:'#188268', Other:'#9AA09E'
};
const CAT_ICON = {Dining:'utensils', Groceries:'basket', Transport:'car', Shopping:'bag',
  Entertainment:'ticket', Utilities:'plug', Health:'heart', Travel:'plane', Other:'more'};

function CatIcon({cat, size=40, theme='light'}) {
  const tint = CAT_TINT[cat] || '#9AA09E';
  const bg = theme==='dark' ? tint+'33' : tint+'1F'; // 12% / 20%
  return (
    <div style={{width:size, height:size, borderRadius:'50%', background:bg,
      display:'inline-flex', alignItems:'center', justifyContent:'center', color:tint, flexShrink:0}}>
      <Ico d={icons[CAT_ICON[cat]]} size={size*0.5}/>
    </div>
  );
}

// Transaction row (canonical)
function TxRow({merchant, cat, date, amount, receipt, aiScanned, room, theme='light', selected, last}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{
      display:'flex', alignItems:'center', padding:'12px 16px', gap:12,
      background: selected? (theme==='dark'?'#06463B': '#E6F4F0'):c.surface,
      borderBottom: last?'none':`1px solid ${c.bSubtle}`, minHeight:64
    }}>
      <CatIcon cat={cat} theme={theme}/>
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:16, fontWeight:500, color:c.primary, fontFamily:window.FONT, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{merchant}</div>
        <div style={{fontSize:14, color:c.secondary, fontFamily:window.FONT, marginTop:2, display:'flex', alignItems:'center', gap:6}}>
          <span>{cat}</span><span>·</span><span>{date}</span>
          {aiScanned && <span style={{marginLeft:4, padding:'2px 6px', background:c.muted, borderRadius:4, fontSize:11, fontWeight:600, color:c.secondary, letterSpacing:0.3, textTransform:'uppercase'}}>AI</span>}
        </div>
      </div>
      <div style={{textAlign:'right', display:'flex', alignItems:'center', gap:8}}>
        {receipt && <span style={{color:c.tertiary}}><Ico d={icons.paperclip} size={14}/></span>}
        <div style={{fontSize:16, fontWeight:600, color:c.primary, fontFamily:window.FONT, fontVariantNumeric:'tabular-nums', letterSpacing:-0.1}}>{amount}</div>
      </div>
    </div>
  );
}

// Amount display
function Amount({value, variant='default', delta, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  const sizes = {hero:40, large:24, default:16, inline:14};
  const weights = {hero:600, large:600, default:600, inline:500};
  return (
    <span style={{fontSize:sizes[variant], fontWeight:weights[variant], color:c.primary,
      fontFamily:window.FONT, fontVariantNumeric:'tabular-nums', letterSpacing: variant==='hero'?-0.4:-0.1}}>{value}</span>
  );
}

// Budget progress bar
function BudgetBar({pct, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  let fill = '#2F8F5E';
  if (pct >= 100) fill = '#C5443E';
  else if (pct >= 70) fill = '#D49A2B';
  const w = Math.min(pct, 100);
  const over = pct > 100 ? (pct-100)/pct*100 : 0;
  return (
    <div style={{height:8, borderRadius:999, background:c.muted, overflow:'hidden', position:'relative'}}>
      <div style={{width:`${w}%`, height:'100%', background:fill, borderRadius:999}}/>
      {over>0 && <div style={{position:'absolute', top:0, right:0, width:`${over}%`, height:'100%', background:'#9D332E'}}/>}
    </div>
  );
}

// Toggle
function Toggle({on, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{width:48, height:28, borderRadius:999, background: on?c.brand:c.bDefault, padding:2, display:'inline-flex',
      transition:'background 180ms'}}>
      <div style={{width:24, height:24, borderRadius:'50%', background:'#fff', marginLeft:on?20:0,
        boxShadow:'0 1px 2px rgba(17,22,19,0.12)', transition:'margin-left 180ms'}}/>
    </div>
  );
}

// Checkbox, radio
function Checkbox({checked, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{width:20, height:20, borderRadius:4, border:`1.5px solid ${checked?c.brand:c.bStrong}`,
      background: checked?c.brand:'transparent', display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
      {checked && <Ico d={icons.check} size={14} stroke='#fff' sw={3}/>}
    </div>
  );
}
function Radio({checked, theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{width:20, height:20, borderRadius:'50%', border:`1.5px solid ${checked?c.brand:c.bStrong}`,
      display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
      {checked && <div style={{width:10, height:10, borderRadius:'50%', background:c.brand}}/>}
    </div>
  );
}

// Phone frame
function Phone({children, theme='light', label}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <div style={{width:320, display:'flex', flexDirection:'column', alignItems:'center'}}>
      <div style={{
        width:320, height:640, borderRadius:36, background:c.canvas, overflow:'hidden',
        border:`1px solid ${theme==='dark'?'#2E3230':'#D4D4CE'}`,
        boxShadow:'0 4px 12px rgba(17,22,19,0.08)',
        position:'relative', fontFamily:window.FONT
      }}>
        {/* status bar */}
        <div style={{height:28, display:'flex', justifyContent:'space-between', alignItems:'center', padding:'0 18px',
          fontSize:12, fontWeight:600, color:c.primary}}>
          <span>9:41</span>
          <span style={{display:'flex', gap:4, alignItems:'center'}}>
            <Ico d={icons.wifi} size={12}/>
          </span>
        </div>
        <div style={{height:612, overflow:'hidden'}}>{children}</div>
      </div>
      {label && <div style={{marginTop:10, fontSize:12, color:window.T.tertiary, fontFamily:window.FONT}}>{label}</div>}
    </div>
  );
}

Object.assign(window, {Header, SwatchRow, Swatch, Section, Label,
  LoitButton, LoitChip, LoitInput, LoitCard, Avatar, AvatarStack, CatIcon, TxRow,
  Amount, BudgetBar, Toggle, Checkbox, Radio, Phone, CAT_TINT, CAT_ICON});
