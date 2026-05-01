// Scan flow + Add/Edit expense form

function ScanCamera() {
  return (
    <PhoneS label="01 · Scan · capture" caption="Camera viewport · receipt frame guide" dark>
      <div style={{height:'100%', background:'#0A0C0B', position:'relative', color:'#fff', fontFamily:FONT}}>
        <div style={{padding:'10px 12px', display:'flex', alignItems:'center', justifyContent:'space-between'}}>
          <div style={{width:36, height:36, borderRadius:'50%', background:'rgba(0,0,0,0.4)', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.x} size={20} stroke="#fff"/></div>
          <div style={{padding:'4px 10px', background:'rgba(15,110,92,0.8)', borderRadius:999, fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase'}}>Receipt</div>
          <div style={{width:36, height:36, borderRadius:'50%', background:'rgba(0,0,0,0.4)', display:'inline-flex', alignItems:'center', justifyContent:'center', fontSize:11, fontWeight:600}}>FLASH</div>
        </div>
        <div style={{position:'absolute', top:80, left:30, right:30, bottom:200, border:'2px solid rgba(255,255,255,0.85)', borderRadius:16}}>
          {[['top','left'],['top','right'],['bottom','left'],['bottom','right']].map(([v,h], i) => (
            <div key={i} style={{position:'absolute', [v]:-2, [h]:-2, width:24, height:24, borderTop:v==='top'?'4px solid #F5BC6D':'none', borderBottom:v==='bottom'?'4px solid #F5BC6D':'none', borderLeft:h==='left'?'4px solid #F5BC6D':'none', borderRight:h==='right'?'4px solid #F5BC6D':'none', borderRadius:v+h==='topleft'?'8px 0 0 0':v+h==='topright'?'0 8px 0 0':v+h==='bottomleft'?'0 0 0 8px':'0 0 8px 0'}}/>
          ))}
          <div style={{position:'absolute', top:'50%', left:'50%', transform:'translate(-50%,-50%)', textAlign:'center', color:'rgba(255,255,255,0.85)', fontSize:13, fontWeight:500}}>Align receipt within frame</div>
        </div>
        <div style={{position:'absolute', bottom:0, left:0, right:0, padding:'24px 24px 32px'}}>
          <div style={{display:'flex', alignItems:'center', justifyContent:'space-between'}}>
            <div style={{width:48, height:48, borderRadius:8, background:`repeating-linear-gradient(135deg, #2E3230 0 4px, #1F2321 4px 8px)`, border:'1px solid rgba(255,255,255,0.2)'}}/>
            <div style={{width:80, height:80, borderRadius:'50%', background:'#fff', border:'4px solid rgba(255,255,255,0.4)', display:'flex', alignItems:'center', justifyContent:'center'}}>
              <div style={{width:64, height:64, borderRadius:'50%', background:'#fff', boxShadow:'0 0 0 1px #0A0C0B inset'}}/>
            </div>
            <div style={{width:48, height:48, borderRadius:'50%', background:'rgba(255,255,255,0.15)', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.edit} size={20} stroke="#fff"/></div>
          </div>
          <div style={{marginTop:14, height:32, background:'rgba(0,0,0,0.4)', borderRadius:8, padding:2, display:'flex'}}>
            {['Receipt','Bill split','Manual'].map((s,i) => (
              <div key={s} style={{flex:1, display:'flex', alignItems:'center', justifyContent:'center', fontSize:12, fontWeight:600, color:i===0?'#0A0C0B':'rgba(255,255,255,0.7)', background:i===0?'#fff':'transparent', borderRadius:6}}>{s}</div>
            ))}
          </div>
        </div>
      </div>
    </PhoneS>
  );
}

function ScanProcessing() {
  return (
    <PhoneS label="02 · Scan · processing" caption="Captured image with progress bar overlay">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Reading receipt" leading={<CloseBtn/>}/>
        <div style={{flex:1, padding:'20px 24px', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', textAlign:'center', fontFamily:FONT}}>
          <div style={{width:160, height:220, borderRadius:12, background:`repeating-linear-gradient(180deg, #fff 0 28px, ${T.n100} 28px 30px)`, border:`1px solid ${T.bDefault}`, position:'relative', overflow:'hidden', boxShadow:'0 4px 12px rgba(17,22,19,0.08)'}}>
            <div style={{position:'absolute', top:0, left:0, right:0, height:6, background:`linear-gradient(90deg, transparent, ${T.brand}, transparent)`, animation:'loit-shimmer 1.4s infinite'}}/>
            <div style={{padding:12}}>
              <div style={{height:8, width:'70%', background:T.n300, borderRadius:2, marginBottom:8}}/>
              <div style={{height:6, width:'50%', background:T.n200, borderRadius:2, marginBottom:14}}/>
              {[60, 80, 70, 90, 50].map((w,i) => (
                <div key={i} style={{display:'flex', justifyContent:'space-between', marginBottom:6}}>
                  <div style={{height:5, width:w, background:T.n200, borderRadius:2}}/>
                  <div style={{height:5, width:24, background:T.n200, borderRadius:2}}/>
                </div>
              ))}
            </div>
          </div>
          <div style={{marginTop:24, fontSize:18, fontWeight:600, color:T.primary, letterSpacing:-0.1}}>Reading your receipt…</div>
          <div style={{fontSize:13, color:T.secondary, marginTop:6, maxWidth:240}}>Usually takes about 2 seconds. We're extracting merchant, total, and items.</div>
          <div style={{marginTop:18, width:200, height:6, background:T.muted, borderRadius:999, overflow:'hidden'}}>
            <div style={{width:'62%', height:'100%', background:T.brand, borderRadius:999}}/>
          </div>
          <div style={{marginTop:8, fontSize:11, color:T.tertiary, fontFamily:MONO}}>62% · Extracting line items</div>
        </div>
      </div>
    </PhoneS>
  );
}

function ScanReviewLow() {
  return (
    <PhoneS label="03 · Review · low confidence" caption="AI returned partial. Yellow chips on uncertain fields.">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Confirm receipt" leading={<CloseBtn/>} trailing={<span style={{padding:'4px 8px', background:T.amber50, color:T.amber700, fontSize:10, fontWeight:600, borderRadius:4, letterSpacing:0.4, textTransform:'uppercase'}}>Review</span>}/>
        <div style={{flex:1, overflowY:'auto', padding:16}}>
          <div style={{padding:'10px 12px', background:T.amber50, color:T.amber700, borderRadius:10, marginBottom:12, fontSize:12, display:'flex', gap:8, fontFamily:FONT}}>
            <Ico d={icons.alert} size={16}/>
            <div>Some fields look uncertain. Tap to confirm.</div>
          </div>
          <LoitInput label="Amount" value="85.000" leading={<span style={{fontSize:15, fontWeight:600, color:T.secondary}}>Rp</span>}/>
          <div style={{height:10}}/>
          <LoitInput label="Merchant" value="Warung Sari" trailing={<span style={{padding:'2px 6px', background:T.amber50, color:T.amber700, fontSize:10, fontWeight:600, borderRadius:4, textTransform:'uppercase'}}>?</span>}/>
          <div style={{fontSize:12, color:T.amber700, marginTop:6, fontFamily:FONT}}>We weren't sure between "Warung Sari" and "Warung Sari Rasa".</div>
          <div style={{height:10}}/>
          <LoitInput label="Date" value="Today · 14.30"/>
          <div style={{height:10}}/>
          <LoitInput label="Category" value="Dining" trailing={<Ico d={icons.chevR} size={16}/>}/>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`, display:'flex', gap:10}}>
          <LoitButton size="m" variant="secondary" label="Discard" fullWidth/>
          <LoitButton size="m" label="Save" fullWidth/>
        </div>
      </div>
    </PhoneS>
  );
}

function ScanSuccess() {
  return (
    <PhoneS label="04 · Saved · success" caption="Snackbar confirms · keep momentum">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <div style={{padding:'8px 16px 10px'}}>
          <div style={{fontSize:20, fontWeight:600, color:T.primary, fontFamily:FONT, letterSpacing:-0.2}}>Hi, Maria</div>
        </div>
        <div style={{flex:1, overflowY:'auto', padding:'6px 16px 88px'}}>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, padding:16}}>
            <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, fontFamily:FONT}}>Spent · November</div>
            <div style={{fontSize:36, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.3, marginTop:4, fontFamily:FONT}}>Rp 4.320.000</div>
          </div>
          <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, margin:'14px 4px 8px', fontFamily:FONT}}>Recent</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <TxRow merchant="Warung Sari Rasa" cat="Dining" date="Just now" amount="Rp 85.000" aiScanned/>
            <TxRow merchant="Shell Kemang" cat="Transport" date="Today" amount="Rp 150.000" receipt last/>
          </div>
        </div>
        <div style={{position:'absolute', bottom:80, left:16, right:16, background:'#1B2D24', color:'#E0F2E8', padding:'12px 14px', borderRadius:12, display:'flex', alignItems:'center', gap:10, fontFamily:FONT, boxShadow:'0 4px 12px rgba(17,22,19,0.16)'}}>
          <div style={{width:24, height:24, borderRadius:'50%', background:'#2F8F5E', color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.check} size={14} sw={3}/></div>
          <div style={{flex:1}}>
            <div style={{fontSize:14, fontWeight:600}}>Saved.</div>
            <div style={{fontSize:12, color:'#9DC9B0'}}>Rp 85.000 · Warung Sari Rasa</div>
          </div>
          <div style={{fontSize:13, fontWeight:600, color:'#67B5A0'}}>UNDO</div>
        </div>
        <TabBar/>
      </div>
    </PhoneS>
  );
}

function ScanArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="D · Scan Flow" title="Camera → processing → review → saved" subtitle="The flagship interaction. Camera with frame guide, processing with anatomy, low-confidence review, saved snackbar with UNDO."/>
      <ScreensGrid>
        <ScanCamera/>
        <ScanProcessing/>
        <ScanReviewLow/>
        <ScanSuccess/>
      </ScreensGrid>
    </div>
  );
}

// ─────────── Add / Edit Expense ───────────

function AddExpense() {
  return (
    <PhoneS label="01 · Add expense · empty" caption="Sticky CTA · grouped fields · numeric keypad ready">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Add expense" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:16}}>
          <div style={{textAlign:'center', padding:'20px 0 24px'}}>
            <div style={{fontSize:13, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase', fontFamily:FONT}}>Amount</div>
            <div style={{fontSize:48, fontWeight:600, color:T.tertiary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.5, marginTop:6, fontFamily:FONT}}>
              <span style={{fontSize:22, color:T.secondary, marginRight:4}}>Rp</span>0
            </div>
            <div style={{marginTop:8}}>
              <span style={{padding:'4px 10px', background:T.muted, borderRadius:999, fontSize:11, fontWeight:600, color:T.secondary, fontFamily:FONT}}>IDR · ID ▾</span>
            </div>
          </div>
          <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, marginBottom:8, fontFamily:FONT}}>Details</div>
          <LoitInput label="Merchant" placeholder="What did you buy?" />
          <div style={{height:10}}/>
          <LoitInput label="Category" value="Choose…" trailing={<Ico d={icons.chevR} size={16}/>}/>
          <div style={{height:10}}/>
          <LoitInput label="Date" value="Today · 14.30"/>
          <div style={{height:14}}/>
          <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, marginBottom:8, fontFamily:FONT}}>Save to</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:14, fontFamily:FONT}}>
            <label style={{display:'flex', gap:10, alignItems:'center', padding:'6px 0'}}><Radio checked/><span style={{fontSize:14, color:T.primary}}>My Finances</span></label>
            <label style={{display:'flex', gap:10, alignItems:'center', padding:'6px 0'}}><Radio checked={false}/><span style={{fontSize:14, color:T.primary}}>Apartment 4B</span></label>
            <label style={{display:'flex', gap:10, alignItems:'center', padding:'6px 0'}}><Radio checked={false}/><span style={{fontSize:14, color:T.primary}}>Bali Trip</span></label>
          </div>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Save expense" disabled/>
        </div>
      </div>
    </PhoneS>
  );
}

function CategoryPicker() {
  const cats = [['Dining','utensils','#F2A85C'],['Groceries','basket','#2F8F5E'],['Transport','car','#3E7AC5'],['Shopping','bag','#B15FC0'],['Entertainment','ticket','#E06B8A'],['Utilities','plug','#5A6160'],['Health','heart','#C5443E'],['Travel','plane','#188268'],['Other','more','#9AA09E']];
  return (
    <PhoneS label="02 · Category picker · sheet" caption="Modal sheet · 9 categories · search">
      <div style={{height:'100%', background:'rgba(0,0,0,0.45)', position:'relative'}}>
        <div style={{position:'absolute', bottom:0, left:0, right:0, top:80, background:T.surface, borderRadius:'24px 24px 0 0', display:'flex', flexDirection:'column'}}>
          <div style={{width:36, height:4, background:T.bStrong, borderRadius:999, margin:'10px auto 14px'}}/>
          <div style={{padding:'0 20px 12px', display:'flex', justifyContent:'space-between', alignItems:'center'}}>
            <div style={{fontSize:18, fontWeight:600, color:T.primary, fontFamily:FONT, letterSpacing:-0.1}}>Pick a category</div>
            <button style={{background:'transparent', border:'none', color:T.brand, fontSize:14, fontWeight:600, fontFamily:FONT}}>Done</button>
          </div>
          <div style={{padding:'0 16px 12px'}}>
            <div style={{height:40, background:T.muted, borderRadius:10, padding:'0 12px', display:'flex', alignItems:'center', gap:8, fontFamily:FONT}}>
              <Ico d={icons.search} size={16} stroke={T.secondary}/>
              <div style={{flex:1, fontSize:14, color:T.tertiary}}>Search categories</div>
            </div>
          </div>
          <div style={{flex:1, overflowY:'auto'}}>
            {cats.map(([n,ic,col], i) => (
              <div key={n} style={{display:'flex', alignItems:'center', padding:'12px 20px', gap:12, borderBottom:i===cats.length-1?'none':`1px solid ${T.bSubtle}`, background:i===0?T.teal50:'transparent'}}>
                <div style={{width:36, height:36, borderRadius:'50%', background:col+'1F', color:col, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons[ic]} size={18}/></div>
                <div style={{flex:1, fontSize:15, color:T.primary, fontFamily:FONT, fontWeight:i===0?600:500}}>{n}</div>
                {i===0 && <Ico d={icons.check} size={20} stroke={T.brand} sw={2.5}/>}
              </div>
            ))}
          </div>
        </div>
      </div>
    </PhoneS>
  );
}

function AddExpenseFilled() {
  return (
    <PhoneS label="03 · Filled · ready to save" caption="All required fields valid · primary CTA enabled · attach receipt option">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Add expense" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:16}}>
          <div style={{textAlign:'center', padding:'14px 0 18px'}}>
            <div style={{fontSize:13, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase', fontFamily:FONT}}>Amount</div>
            <div style={{fontSize:48, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.5, marginTop:6, fontFamily:FONT}}>
              <span style={{fontSize:22, color:T.secondary, marginRight:4}}>Rp</span>85.000
            </div>
          </div>
          <LoitInput label="Merchant" value="Warung Sari Rasa"/>
          <div style={{height:10}}/>
          <LoitInput label="Category" value="Dining" leading={<Ico d={icons.utensils} size={16} stroke="#F2A85C"/>} trailing={<Ico d={icons.chevR} size={16}/>}/>
          <div style={{height:10}}/>
          <LoitInput label="Date" value="Today · 14.30"/>
          <div style={{height:10}}/>
          <LoitInput label="Notes (optional)" placeholder="Add a note"/>
          <div style={{marginTop:14, padding:12, background:T.surface, border:`1px dashed ${T.bDefault}`, borderRadius:12, display:'flex', alignItems:'center', gap:10, fontFamily:FONT}}>
            <div style={{width:36, height:36, borderRadius:8, background:T.muted, display:'inline-flex', alignItems:'center', justifyContent:'center', color:T.secondary}}><Ico d={icons.camera} size={18}/></div>
            <div style={{flex:1}}>
              <div style={{fontSize:13, fontWeight:600, color:T.primary}}>Attach a receipt</div>
              <div style={{fontSize:11, color:T.secondary}}>Optional. We'll keep it in your timeline.</div>
            </div>
          </div>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Save expense"/>
        </div>
      </div>
    </PhoneS>
  );
}

function EditExpense() {
  return (
    <PhoneS label="04 · Edit · with audit hint" caption="Editing AI-scanned · shows original values">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Edit expense" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:16, fontFamily:FONT}}>
          <div style={{padding:'10px 12px', background:T.teal50, color:T.teal800, borderRadius:10, marginBottom:14, fontSize:12, display:'flex', gap:8}}>
            <Ico d={icons.info} size={16}/>
            <div>This was AI-scanned. Edits keep the original in history.</div>
          </div>
          <LoitInput label="Amount" value="85.000" leading={<span style={{fontSize:15, fontWeight:600, color:T.secondary}}>Rp</span>}/>
          <div style={{fontSize:11, color:T.tertiary, marginTop:6}}>Original: Rp 85.000</div>
          <div style={{height:10}}/>
          <LoitInput label="Merchant" value="Warung Sari Rasa — Kemang"/>
          <div style={{fontSize:11, color:T.tertiary, marginTop:6}}>Original: Warung Sari Rasa</div>
          <div style={{height:10}}/>
          <LoitInput label="Category" value="Dining" leading={<Ico d={icons.utensils} size={16} stroke="#F2A85C"/>} trailing={<Ico d={icons.chevR} size={16}/>}/>
          <div style={{height:10}}/>
          <LoitInput label="Date" value="Today · 14.30"/>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`, display:'flex', gap:10}}>
          <LoitButton size="m" variant="ghost" label="Cancel" fullWidth/>
          <LoitButton size="m" label="Save changes" fullWidth/>
        </div>
      </div>
    </PhoneS>
  );
}

function AddExpenseArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="E · Add / Edit Expense" title="The fallback to scan: 5-second manual entry" subtitle="Empty form · category sheet · ready-to-save · edit with audit. Currency-aware, room-aware."/>
      <ScreensGrid>
        <AddExpense/>
        <CategoryPicker/>
        <AddExpenseFilled/>
        <EditExpense/>
      </ScreensGrid>
    </div>
  );
}

Object.assign(window, {ScanArtboard, AddExpenseArtboard});
