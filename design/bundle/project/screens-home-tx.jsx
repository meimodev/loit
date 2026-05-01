// Home / Dashboard screens (3 variants) + Transactions (feed, detail, search, multi-select)
// Layout DNA from money-tracker references: month nav app bar, stat-triple header,
// underline tab strip, day-section heavy headers, edge-to-edge tx lines, FAB stack.

function HomeDefault({theme='light'}) {
  const c = theme==='dark'?TD:T;
  return (
    <PhoneS label="01 · Home · default" caption="Returning user · mid-month · stat triple + edge-to-edge feed">
      <div style={{height:'100%', background:c.canvas, display:'flex', flexDirection:'column'}}>
        <AppBarMonth label="Nov 2026" leading={<div style={{width:14}}/>} actions={['star','search','filter']} theme={theme}/>
        <StatTriple stats={[
          ['Income','Rp 8.500k', '#3E7AC5'],
          ['Expenses','Rp 4.235k', '#C5443E'],
          ['Total','Rp 4.265k', c.primary],
        ]} theme={theme}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          {/* Hero summary band — sits within the canvas, not as a card */}
          <div style={{padding:'14px 16px 10px', background:c.canvas, fontFamily:FONT}}>
            <div style={{display:'flex', justifyContent:'space-between', alignItems:'baseline'}}>
              <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:c.secondary}}>Day 18 · 30</div>
              <div style={{fontSize:11, color:c.tertiary}}>Goal Rp 6.200.000</div>
            </div>
            <div style={{fontSize:32, fontWeight:600, color:c.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.4, marginTop:4}}>Rp 4.235.000</div>
            <div style={{marginTop:10, height:5, background:c.muted, borderRadius:999, overflow:'hidden'}}>
              <div style={{width:'68%', height:'100%', background:c.brand}}/>
            </div>
          </div>

          {/* Budgets section — group label + edge-to-edge rows */}
          <GroupLabel theme={theme}>Budgets</GroupLabel>
          {[['Dining','Dining',82,'Rp 1.640k of 2.000k', c.primary],
            ['Groceries','Groceries',48,'Rp 960k of 2.000k', c.primary],
            ['Transport','Transport',125,'Rp 1.250k of 1.000k', '#C5443E']].map(([cat,n,p,sub,col],i,a) => {
            const tint = CAT_TINT[cat]; const ic = CAT_ICON[cat];
            return (
              <div key={n} style={{display:'flex', alignItems:'center', padding:'12px 16px', gap:12,
                borderBottom:i===a.length-1?'none':`1px solid ${c.bSubtle}`, background:c.surface, fontFamily:FONT}}>
                <div style={{width:36, height:36, borderRadius:'50%', background:tint+'1F', color:tint, display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0}}>
                  <Ico d={icons[ic]} size={18}/>
                </div>
                <div style={{flex:1, minWidth:0}}>
                  <div style={{display:'flex', justifyContent:'space-between', fontSize:13, color:c.primary, fontWeight:500}}>
                    <span>{n}</span><span style={{fontWeight:600, color:col, fontVariantNumeric:'tabular-nums'}}>{p}%</span>
                  </div>
                  <div style={{marginTop:4, height:4, background:c.muted, borderRadius:999, overflow:'hidden'}}>
                    <div style={{width:Math.min(100,p)+'%', height:'100%', background:p>100?'#C5443E':tint}}/>
                  </div>
                  <div style={{fontSize:11, color:c.tertiary, marginTop:4, fontVariantNumeric:'tabular-nums'}}>{sub}</div>
                </div>
              </div>
            );
          })}

          {/* Recent — edge-to-edge tx lines */}
          <GroupLabel theme={theme}>Recent</GroupLabel>
          <TxLine cat="Dining" merchant="Warung Sari Rasa" account="BCA · 14.30" amount="Rp 85.000" theme={theme}/>
          <TxLine cat="Transport" merchant="Shell Kemang" account="Cash · 12.00" amount="Rp 150.000" theme={theme}/>
          <TxLine cat="Groceries" merchant="Alfamart" account="Gopay · Yesterday" amount="Rp 42.500" theme={theme}/>
        </div>
        <FabStack theme={theme} primaryColor={c.accent}/>
        <TabBar active="home" theme={theme}/>
      </div>
    </PhoneS>
  );
}

function HomeEmpty() {
  return (
    <PhoneS label="02 · Home · first day" caption="Empty state · same shell, calm content">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBarMonth label="Nov 2026" leading={<div style={{width:14}}/>} actions={['star','search','filter']}/>
        <StatTriple stats={[['Income','Rp 0','#3E7AC5'],['Expenses','Rp 0','#C5443E'],['Total','Rp 0', T.primary]]}/>
        <div style={{flex:1, padding:'20px 20px', paddingBottom:TAB_PAD, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', textAlign:'center', fontFamily:FONT}}>
          <div style={{width:120, height:120, borderRadius:16, background:`repeating-linear-gradient(135deg, ${T.teal50} 0 8px, ${T.surface} 8px 16px)`, display:'inline-flex', alignItems:'center', justifyContent:'center', marginBottom:20, border:`1px dashed ${T.bDefault}`, color:T.brand}}>
            <Ico d={icons.receipt} size={40} sw={1.5}/>
          </div>
          <div style={{fontSize:18, fontWeight:600, color:T.primary, letterSpacing:-0.1}}>Ready when you are</div>
          <div style={{fontSize:13, color:T.secondary, marginTop:6, maxWidth:240, lineHeight:'18px'}}>Snap your first receipt or type in an expense — both take about five seconds.</div>
          <div style={{display:'flex', gap:10, marginTop:18}}>
            <LoitButton size="m" leading={<Ico d={icons.camera} size={16} stroke="#fff"/>} label="Scan"/>
            <LoitButton size="m" variant="secondary" leading={<Ico d={icons.plus} size={16}/>} label="Add manually"/>
          </div>
        </div>
        <FabStack primaryColor={T.accent}/>
        <TabBar active="home"/>
      </div>
    </PhoneS>
  );
}

function HomeDense() {
  return (
    <PhoneS label="03 · Home · late month · alert" caption="Power-user view · alert banner · dense layout">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBarMonth label="Nov 2026" leading={<div style={{width:14}}/>} actions={['star','search','filter']}/>
        <StatTriple stats={[
          ['Income','Rp 8.500k','#3E7AC5'],
          ['Expenses','Rp 6.142k','#C5443E'],
          ['Total','Rp 2.358k', T.primary]
        ]}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          <div style={{padding:'10px 14px', background:'#FBEAE9', color:'#9D332E', fontSize:13, fontWeight:500, display:'flex', gap:10, alignItems:'center', fontFamily:FONT, borderBottom:`1px solid ${T.bSubtle}`}}>
            <Ico d={icons.alert} size={18}/>
            <div style={{flex:1}}>2 budgets over. Day 28 of 30.</div>
            <Ico d={icons.chevR} size={16}/>
          </div>
          <GroupLabel>Quick stats</GroupLabel>
          {[['Budgets','4 of 6 on track','#2F8F5E'],['Rooms','3 active','#0F6E5C'],['Recurring','5 upcoming · Rp 1.2M','#3E7AC5'],['Scans this month','22','#E8922F']].map(([k,v,col],i,a) => (
            <LineRow key={k} label={k} value={v} valueColor={col} theme="light"/>
          ))}
          <GroupLabel>Today</GroupLabel>
          <TxLine cat="Dining" merchant="Starbucks Plaza" account="BCA · 14.30" amount="Rp 68.000"/>
          <TxLine cat="Transport" merchant="Grab" account="Gopay · 13.10" amount="Rp 28.500"/>
          <TxLine cat="Shopping" merchant="Tokopedia" account="Shopee Pay · 11.00" amount="Rp 349.000"/>
        </div>
        <FabStack primaryColor={T.accent}/>
        <TabBar active="home"/>
      </div>
    </PhoneS>
  );
}

function HomeArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="B · Home / Dashboard" title="Three states · stat-triple shell" subtitle="Default · Empty (first day) · Dense (late-month, alerts). Layout from money-tracker references — flat tabs, edge-to-edge rows, FAB stack."/>
      <ScreensGrid>
        <HomeDefault/>
        <HomeEmpty/>
        <HomeDense/>
      </ScreensGrid>
    </div>
  );
}

// ─────────────────── Transactions ──────────────────────

function TxFeed() {
  return (
    <PhoneS label="01 · Daily · grouped feed" caption="Underline tabs · day-section headers w/ per-day totals · FAB stack">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBarMonth label="Nov 2026" leading={<div style={{width:14}}/>} actions={['star','search','filter']}/>
        <TabStrip tabs={['Daily','Calendar','Monthly','Total','Note']} active={0}/>
        <StatTriple stats={[
          ['Income','Rp 8.500.000','#3E7AC5'],
          ['Expenses','Rp 4.235.000','#C5443E'],
          ['Total','Rp 4.265.000', T.primary],
        ]}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD, background:T.canvas}}>
          <DayHeader day="12" weekday="Tue" weekdayColor="#3E7AC5" dateSub="11.2026" income="Rp 0" expense="Rp 235.000"/>
          <TxLine cat="Dining" merchant="Warung Sari Rasa" account="BCA" amount="Rp 85.000"/>
          <TxLine cat="Transport" merchant="Shell Kemang" account="Cash" amount="Rp 150.000"/>

          <DayHeader day="11" weekday="Mon" weekdayColor="#188268" dateSub="11.2026" income="Rp 8.500.000" expense="Rp 98.500"/>
          <TxLine cat="Other" merchant="Salary · ABC Corp" account="Mandiri payroll" amount="Rp 8.500.000" isIncome/>
          <TxLine cat="Groceries" merchant="Alfamart, milk + bread" account="Gopay" amount="Rp 42.500"/>
          <TxLine cat="Dining" merchant="Go-Food, Bakmi GM" account="Shopee Pay" amount="Rp 56.000"/>

          <DayHeader day="10" weekday="Sun" weekdayColor="#C5443E" dateSub="11.2026" income="Rp 0" expense="Rp 240.990"/>
          <TxLine cat="Entertainment" merchant="Apple Music · family" account="BCA · USD" amount="Rp 169.000"/>
          <TxLine cat="Health" merchant="Halodoc, paracetamol" account="Gopay later" amount="Rp 71.990"/>

          <DayHeader day="09" weekday="Sat" weekdayColor="#3E7AC5" dateSub="11.2026" income="Rp 0" expense="Rp 425.000"/>
          <TxLine cat="Shopping" merchant="Tokopedia · charger" account="BCA" amount="Rp 165.000"/>
          <TxLine cat="Travel" merchant="Grab · airport" account="Cash" amount="Rp 260.000"/>
        </div>
        <FabStack primaryColor={T.accent}/>
        <TabBar active="tx"/>
      </div>
    </PhoneS>
  );
}

function TxDetail() {
  return (
    <PhoneS label="02 · Transaction detail" caption="Photo, line items, notes, audit log">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="" leading={<BackBtn/>} trailing={<IconBtn d={icons.more}/>}/>
        <div style={{flex:1, overflowY:'auto'}}>
          <div style={{padding:'4px 20px 20px', background:T.surface}}>
            <CatIcon cat="Dining" size={48}/>
            <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, marginTop:12, fontFamily:FONT}}>Dining · Warung Sari Rasa</div>
            <div style={{fontSize:36, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.3, marginTop:4, fontFamily:FONT}}>Rp 85.000</div>
            <div style={{fontSize:13, color:T.secondary, marginTop:4, fontFamily:FONT}}>Today · 14.30 · BCA · 4839</div>
            <span style={{marginTop:10, display:'inline-flex', alignItems:'center', padding:'3px 8px', background:T.teal100, color:T.teal800, fontSize:11, fontWeight:600, borderRadius:4, letterSpacing:0.3, textTransform:'uppercase'}}>AI-scanned · 98%</span>
          </div>
          <GroupLabel>Receipt</GroupLabel>
          <div style={{padding:'12px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, display:'flex', gap:12}}>
            <div style={{width:90, height:120, borderRadius:8, background:`repeating-linear-gradient(135deg, ${T.n100} 0 6px, ${T.n200} 6px 12px)`, border:`1px solid ${T.bDefault}`, flexShrink:0, position:'relative'}}>
              <div style={{position:'absolute', bottom:6, left:6, padding:'2px 6px', background:'rgba(17,22,19,0.7)', color:'#fff', fontSize:10, borderRadius:4, fontFamily:FONT}}>Tap to view</div>
            </div>
            <div style={{flex:1, fontFamily:FONT}}>
              {[['Nasi goreng ayam','Rp 35.000'],['Es teh','Rp 15.000'],['Service 10%','Rp 10.000'],['Tax 11%','Rp 9.350']].map(([n,a],i,arr) => (
                <div key={n} style={{display:'flex', justifyContent:'space-between', fontSize:12, padding:'5px 0', color:T.primary, borderBottom:i===arr.length-1?'none':`1px solid ${T.bSubtle}`}}>
                  <span>{n}</span><span style={{fontVariantNumeric:'tabular-nums', fontWeight:500}}>{a}</span>
                </div>
              ))}
            </div>
          </div>
          <GroupLabel>Notes</GroupLabel>
          <div style={{padding:'12px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, fontSize:13, color:T.primary, lineHeight:'18px', fontFamily:FONT}}>Team lunch with design — reimbursable.</div>
          <GroupLabel>Activity</GroupLabel>
          <div style={{padding:'10px 16px', background:T.surface}}>
            {[['Created · AI scan','Today · 14.31'],['Category auto-assigned · Dining','Today · 14.31'],['Edited note','Today · 14.45']].map(([a,t],i) => (
              <div key={i} style={{display:'flex', alignItems:'flex-start', gap:8, padding:'6px 0', fontFamily:FONT}}>
                <div style={{width:6, height:6, borderRadius:'50%', background:T.brand, marginTop:6, flexShrink:0}}/>
                <div style={{flex:1}}>
                  <div style={{fontSize:12, color:T.primary}}>{a}</div>
                  <div style={{fontSize:11, color:T.tertiary, fontFamily:MONO}}>{t}</div>
                </div>
              </div>
            ))}
          </div>
          <div style={{height:80}}/>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`, display:'flex', gap:10}}>
          <LoitButton variant="secondary" size="m" leading={<Ico d={icons.edit} size={16}/>} label="Edit" fullWidth/>
          <LoitButton variant="destructive" size="m" leading={<Ico d={icons.trash} size={16}/>} label="Delete" fullWidth/>
        </div>
      </div>
    </PhoneS>
  );
}

function TxSearch() {
  return (
    <PhoneS label="03 · Search · active" caption="Live filter · edge-to-edge results">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <div style={{padding:'8px 8px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, display:'flex', alignItems:'center', gap:6}}>
          <CloseBtn/>
          <div style={{flex:1, height:40, background:T.muted, borderRadius:10, display:'flex', alignItems:'center', gap:8, padding:'0 12px', fontFamily:FONT}}>
            <Ico d={icons.search} size={16} stroke={T.secondary}/>
            <div style={{flex:1, fontSize:14, color:T.primary}}>warung</div>
            <Ico d={icons.x} size={16} stroke={T.secondary}/>
          </div>
        </div>
        <div style={{flex:1, overflowY:'auto', paddingBottom:20}}>
          <GroupLabel>Top match · merchant</GroupLabel>
          <TxLine cat="Dining" merchant="Warung Sari Rasa" account="Today · 14.30" amount="Rp 85.000"/>
          <GroupLabel>All results · 7</GroupLabel>
          <TxLine cat="Dining" merchant="Warung Sari Rasa" account="5 Nov · BCA" amount="Rp 92.000"/>
          <TxLine cat="Dining" merchant="Warung Pojok" account="28 Oct · Cash" amount="Rp 65.000"/>
          <TxLine cat="Dining" merchant="Warung Tegal" account="22 Oct · Gopay" amount="Rp 48.000"/>
          <GroupLabel>Recent searches</GroupLabel>
          {['shell','grab','alfamart'].map(s => (
            <div key={s} style={{display:'flex', alignItems:'center', gap:10, padding:'14px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, fontFamily:FONT}}>
              <Ico d={icons.search} size={14} stroke={T.tertiary}/>
              <div style={{flex:1, fontSize:14, color:T.primary}}>{s}</div>
              <Ico d={icons.x} size={14} stroke={T.tertiary}/>
            </div>
          ))}
        </div>
      </div>
    </PhoneS>
  );
}

function TxMultiSelect() {
  return (
    <PhoneS label="04 · Multi-select" caption="Long-press enters · contextual action bar">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <div style={{padding:'6px 8px', background:T.teal700, color:'#fff', fontFamily:FONT, display:'flex', alignItems:'center'}}>
          <button style={{width:40, height:40, borderRadius:'50%', background:'transparent', border:'none', color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.x} size={22} stroke="#fff"/></button>
          <div style={{fontSize:17, fontWeight:600, marginLeft:4, flex:1}}>3 selected</div>
          <button style={{width:40, height:40, borderRadius:'50%', background:'transparent', border:'none', color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.edit} size={20} stroke="#fff"/></button>
          <button style={{width:40, height:40, borderRadius:'50%', background:'transparent', border:'none', color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.trash} size={20} stroke="#fff"/></button>
        </div>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          <DayHeader day="12" weekday="Tue" weekdayColor="#3E7AC5" dateSub="11.2026" income="Rp 0" expense="Rp 235.000"/>
          <div style={{background:T.teal50}}><TxLine cat="Dining" merchant="✓ Warung Sari Rasa" account="BCA · 14.30" amount="Rp 85.000"/></div>
          <div style={{background:T.teal50}}><TxLine cat="Transport" merchant="✓ Shell Kemang" account="Cash · 12.00" amount="Rp 150.000"/></div>
          <DayHeader day="11" weekday="Mon" weekdayColor="#188268" dateSub="11.2026" income="Rp 0" expense="Rp 98.500"/>
          <div style={{background:T.teal50}}><TxLine cat="Groceries" merchant="✓ Alfamart" account="Gopay · 19.20" amount="Rp 42.500"/></div>
          <TxLine cat="Dining" merchant="Go-Food" account="Shopee Pay · 12.45" amount="Rp 56.000"/>
        </div>
        <div style={{position:'absolute', bottom:0, left:0, right:0, padding:'10px 14px', background:T.surface, borderTop:`1px solid ${T.bSubtle}`, display:'flex', gap:8, fontFamily:FONT}}>
          <LoitButton size="m" variant="secondary" leading={<Ico d={icons.edit} size={14}/>} label="Recategorize"/>
          <LoitButton size="m" variant="secondary" label="Move to room"/>
        </div>
      </div>
    </PhoneS>
  );
}

function TransactionsArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="C · Transactions" title="Daily feed · Detail · Search · Multi-select" subtitle="Layout from money-tracker references: month nav + tab strip + stat triple + day-section headers with per-day totals + edge-to-edge rows + FAB stack."/>
      <ScreensGrid>
        <TxFeed/>
        <TxDetail/>
        <TxSearch/>
        <TxMultiSelect/>
      </ScreensGrid>
    </div>
  );
}

// ─────────────────── Accounts (new screen, direct match to ref) ──────────────────────

function AccountsScreen() {
  return (
    <PhoneS label="05 · Accounts · balances" caption="Direct mirror of reference — assets/liabilities triple, grouped balance rows">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Accounts" trailing={<div style={{display:'flex'}}><IconBtn d={icons.chart}/><IconBtn d={icons.more}/></div>}/>
        <StatTriple stats={[
          ['Assets','Rp 6.948k','#3E7AC5'],
          ['Liabilities','Rp 8.119k','#C5443E'],
          ['Total','-Rp 1.171k', T.primary],
        ]}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          <GroupLabel>Accounts <span style={{float:'right', color:'#3E7AC5'}}>Rp 6.948.197</span></GroupLabel>
          <LineRow label="Cash" value="Rp 125.000" valueColor="#3E7AC5"/>
          <LineRow label="Mandiri payroll" value="Rp 0" valueColor={T.tertiary}/>
          <LineRow label="BCA" value="Rp 6.101.134" valueColor={T.primary}/>
          <LineRow label="Shopee Pay" value="Rp 20.528" valueColor="#3E7AC5"/>
          <LineRow label="Gopay tabungan" value="Rp 101.306" valueColor="#3E7AC5"/>
          <LineRow label="E-Money mandiri" value="Rp 41.999" valueColor="#3E7AC5"/>
          <LineRow label="Astra Pay" value="Rp 98" valueColor="#3E7AC5"/>

          <GroupLabel>Loan <span style={{float:'right', color:'#C5443E'}}>Rp 6.720.000</span></GroupLabel>
          <LineRow label="M" value="Rp 2.050.000" valueColor="#C5443E"/>
          <LineRow label="L2" value="Rp 4.670.000" valueColor="#C5443E"/>
          <LineRow label="KSM" value="-Rp 469.668.796" valueColor={T.primary}/>

          <GroupLabel>Investments <span style={{float:'right', color:T.tertiary}}>Rp 329.950.000</span></GroupLabel>
          <LineRow label="Stock (Stockbit)" value="Rp 329.950.000" valueColor={T.primary}/>
          <LineRow label="Indodax" value="Rp 0" valueColor={T.tertiary}/>
        </div>
        <FabStack primaryColor={T.accent}/>
        <TabBar active="more"/>
      </div>
    </PhoneS>
  );
}

function AccountsArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="K · Accounts" title="Direct application of the reference layout" subtitle="Stat triple · grouped balance rows with section sub-totals · edge-to-edge dividers · flat tab bar."/>
      <ScreensGrid>
        <AccountsScreen/>
      </ScreensGrid>
    </div>
  );
}

Object.assign(window, {HomeArtboard, TransactionsArtboard, AccountsArtboard});
