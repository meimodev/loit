// Rooms screens — the multiplayer mode

function RoomsList() {
  const rooms = [
    ['Bali Trip','#7A4FBF', 3, '12 Nov · 4 expenses today','You owe Alex Rp 145.000'],
    ['Apartment 4B','#0F6E5C', 2, 'Yesterday · rent split','Settled up'],
    ['Movie Night','#C5443E', 5, '5 Nov · 2 expenses','Reza owes you Rp 60.000'],
    ['Office snacks','#F2A85C', 8, '28 Oct','Settled up'],
  ];
  return (
    <PhoneS label="01 · Rooms · list" caption="Distinct from Personal · color identity per room">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Rooms" trailing={<IconBtn d={icons.plus}/>}/>
        <div style={{flex:1, overflowY:'auto', padding:'10px 16px 88px'}}>
          <div style={{padding:'12px 14px', background:'#FDF4E0', color:'#7D5916', borderRadius:12, fontSize:13, fontWeight:500, marginBottom:12, display:'flex', gap:10, alignItems:'center', fontFamily:FONT}}>
            <Ico d={icons.alert} size={18}/>
            <div style={{flex:1}}>You owe Rp 205.000 across 2 rooms.</div>
            <Ico d={icons.chevR} size={16}/>
          </div>
          {rooms.map(([n,col,m,sub,bal]) => (
            <div key={n} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:14, marginBottom:8, display:'flex', alignItems:'center', gap:12, fontFamily:FONT}}>
              <div style={{width:44, height:44, borderRadius:10, background:col, color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center', fontSize:18, fontWeight:600}}>{n[0]}</div>
              <div style={{flex:1, minWidth:0}}>
                <div style={{display:'flex', alignItems:'center', gap:6}}>
                  <div style={{fontSize:15, fontWeight:600, color:T.primary}}>{n}</div>
                  <div style={{fontSize:11, color:T.tertiary}}>· {m} members</div>
                </div>
                <div style={{fontSize:12, color:T.secondary, marginTop:2}}>{sub}</div>
                <div style={{fontSize:12, fontWeight:600, color:bal.includes('owe Alex')?'#9D332E':bal.includes('owes you')?'#227549':T.tertiary, marginTop:3}}>{bal}</div>
              </div>
              <Ico d={icons.chevR} size={16} stroke={T.tertiary}/>
            </div>
          ))}
        </div>
        <TabBar active="rooms"/>
      </div>
    </PhoneS>
  );
}

function RoomDetail() {
  const accent = '#7A4FBF';
  return (
    <PhoneS label="02 · Room · feed" caption="Distinct color identity · presence dot · feed grouped by day">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <div style={{padding:'10px 12px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`}}>
          <div style={{display:'flex', alignItems:'center', gap:8}}>
            <BackBtn/>
            <div style={{width:8, height:8, borderRadius:'50%', background:accent}}/>
            <div style={{fontSize:18, fontWeight:600, color:T.primary, letterSpacing:-0.15, flex:1, fontFamily:FONT}}>Bali Trip</div>
            <IconBtn d={icons.users}/>
            <IconBtn d={icons.settings}/>
          </div>
          <div style={{marginTop:10, display:'flex', alignItems:'center', gap:10}}>
            <AvatarStack members={[{initials:'A',color:accent},{initials:'M',color:'#C5443E'},{initials:'R',color:'#3E7AC5'}]}/>
            <div style={{fontSize:12, color:T.secondary, fontFamily:FONT}}>3 members · Alex is adding an expense…</div>
          </div>
          <div style={{marginTop:12, height:36, background:T.muted, borderRadius:10, padding:2, display:'flex', gap:2}}>
            {['Feed','Budget','Balances'].map((s,i) => (
              <div key={s} style={{flex:1, display:'flex', alignItems:'center', justifyContent:'center', fontSize:13, fontWeight:600, color:i===0?T.primary:T.secondary, background:i===0?T.surface:'transparent', borderRadius:8, fontFamily:FONT}}>{s}</div>
            ))}
          </div>
        </div>
        <div style={{flex:1, overflowY:'auto', padding:'10px 12px 88px', fontFamily:FONT}}>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:12, marginBottom:10}}>
            <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase'}}>Total spent</div>
            <div style={{fontSize:24, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.2, marginTop:2}}>Rp 2.840.000</div>
            <div style={{display:'flex', gap:14, marginTop:8, fontSize:12, color:T.secondary}}>
              <div>You: <strong style={{color:T.primary}}>Rp 1.005.000</strong></div>
              <div>Alex: <strong style={{color:T.primary}}>Rp 1.150.000</strong></div>
              <div>Reza: <strong style={{color:T.primary}}>Rp 685.000</strong></div>
            </div>
          </div>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', margin:'6px 4px 6px'}}>Today</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <div style={{padding:'12px 16px', display:'flex', alignItems:'center', gap:12, borderBottom:`1px solid ${T.bSubtle}`, background:T.surface}}>
              <CatIcon cat="Dining"/>
              <div style={{flex:1}}>
                <div style={{fontSize:15, fontWeight:500, color:T.primary}}>Bebek Bengil</div>
                <div style={{fontSize:12, color:T.secondary, marginTop:2, display:'flex', alignItems:'center', gap:6}}>
                  <Avatar size={16} initials="A" color={accent}/>
                  <span>Alex paid · split 3 ways</span>
                </div>
              </div>
              <div style={{fontSize:15, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>Rp 285.000</div>
            </div>
            <div style={{padding:'12px 16px', display:'flex', alignItems:'center', gap:12}}>
              <CatIcon cat="Transport"/>
              <div style={{flex:1}}>
                <div style={{fontSize:15, fontWeight:500, color:T.primary}}>Taxi to villa</div>
                <div style={{fontSize:12, color:T.secondary, marginTop:2, display:'flex', alignItems:'center', gap:6}}>
                  <Avatar size={16} initials="M" color="#C5443E"/>
                  <span>You paid · split with Reza</span>
                </div>
              </div>
              <div style={{fontSize:15, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>Rp 125.000</div>
            </div>
          </div>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', margin:'14px 4px 6px'}}>Yesterday</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <TxRow merchant="Grocery run" cat="Groceries" date="18.00" amount="Rp 410.000" receipt aiScanned last/>
          </div>
        </div>
        <div style={{position:'absolute', bottom:90, right:18, width:56, height:56, borderRadius:'50%', background:accent, color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center', boxShadow:'0 6px 16px rgba(122,79,191,0.4)'}}><Ico d={icons.plus} size={26} stroke="#fff" sw={2.5}/></div>
        <TabBar active="rooms"/>
      </div>
    </PhoneS>
  );
}

function RoomBalances() {
  return (
    <PhoneS label="03 · Room · balances + settle" caption="Net balances · settle preview · payment options">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Bali Trip · Balances" leading={<BackBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:'14px 16px 80px', fontFamily:FONT}}>
          <div style={{textAlign:'center', padding:'14px 0 18px'}}>
            <div style={{fontSize:13, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase'}}>Your balance</div>
            <div style={{fontSize:36, fontWeight:600, color:'#9D332E', fontVariantNumeric:'tabular-nums', letterSpacing:-0.3, marginTop:4}}>− Rp 145.000</div>
            <div style={{fontSize:13, color:T.secondary, marginTop:2}}>You owe in this room</div>
          </div>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', marginBottom:8}}>Suggested settlements</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <div style={{padding:'14px 16px', display:'flex', alignItems:'center', gap:12, borderBottom:`1px solid ${T.bSubtle}`}}>
              <Avatar size={36} initials="M" color="#C5443E"/>
              <div style={{fontSize:13, color:T.primary, flex:1}}>You <span style={{color:T.secondary}}>pay</span> Alex</div>
              <div style={{fontSize:16, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>Rp 145.000</div>
            </div>
            <div style={{padding:'14px 16px', display:'flex', alignItems:'center', gap:12}}>
              <Avatar size={36} initials="R" color="#3E7AC5"/>
              <div style={{fontSize:13, color:T.primary, flex:1}}>Reza <span style={{color:T.secondary}}>pays</span> Alex</div>
              <div style={{fontSize:16, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>Rp 80.000</div>
            </div>
          </div>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', margin:'18px 0 8px'}}>Pay with</div>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:8}}>
            {[['GoPay','#00AED6'],['OVO','#4C2A86'],['DANA','#118EEA'],['Bank transfer',T.brand]].map(([n,c]) => (
              <div key={n} style={{padding:14, background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, textAlign:'center'}}>
                <div style={{width:32, height:32, borderRadius:8, background:c, margin:'0 auto 6px'}}/>
                <div style={{fontSize:12, fontWeight:600, color:T.primary}}>{n}</div>
              </div>
            ))}
          </div>
          <div style={{marginTop:14, padding:12, background:T.muted, borderRadius:10, fontSize:11, color:T.secondary}}>LOIT records the settlement; the payment happens in your wallet of choice.</div>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`, display:'flex', gap:10}}>
          <LoitButton size="m" variant="secondary" label="Mark settled" fullWidth/>
          <LoitButton size="m" label="Pay Rp 145.000" fullWidth/>
        </div>
      </div>
    </PhoneS>
  );
}

function RoomCreate() {
  const colors = ['#0F6E5C','#F2A85C','#7A4FBF','#C5443E','#3E7AC5','#2F8F5E','#D47A9B','#5A6160'];
  return (
    <PhoneS label="04 · Create room" caption="Choose color identity · invite path">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="New room" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:16, fontFamily:FONT}}>
          <div style={{textAlign:'center', padding:'10px 0 18px'}}>
            <div style={{width:80, height:80, borderRadius:20, background:colors[2], color:'#fff', display:'inline-flex', alignItems:'center', justifyContent:'center', fontSize:36, fontWeight:600, margin:'0 auto'}}>B</div>
          </div>
          <LoitInput label="Room name" value="Bali Trip"/>
          <div style={{height:14}}/>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', marginBottom:8}}>Color identity</div>
          <div style={{display:'flex', gap:10, flexWrap:'wrap'}}>
            {colors.map((c, i) => (
              <div key={c} style={{width:40, height:40, borderRadius:'50%', background:c, border:i===2?`3px solid ${T.primary}`:`3px solid transparent`, display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
                {i===2 && <Ico d={icons.check} size={18} stroke="#fff" sw={3}/>}
              </div>
            ))}
          </div>
          <div style={{height:14}}/>
          <LoitInput label="Default split" value="Equal — 3 ways" trailing={<Ico d={icons.chevR} size={16}/>}/>
          <div style={{height:14}}/>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', marginBottom:8}}>Members · 1</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <div style={{padding:'12px 14px', display:'flex', alignItems:'center', gap:10, borderBottom:`1px solid ${T.bSubtle}`}}>
              <Avatar size={32} initials="M" color="#C5443E"/>
              <div style={{flex:1}}>
                <div style={{fontSize:14, color:T.primary, fontWeight:500}}>You</div>
                <div style={{fontSize:11, color:T.secondary}}>maria@example.com</div>
              </div>
              <span style={{padding:'2px 6px', background:T.muted, fontSize:10, fontWeight:600, borderRadius:4, color:T.secondary, textTransform:'uppercase', letterSpacing:0.4}}>Admin</span>
            </div>
            <div style={{padding:'12px 14px', display:'flex', alignItems:'center', gap:10, color:T.brand, fontWeight:600, fontSize:14}}>
              <Ico d={icons.plus} size={18} stroke={T.brand}/> Invite people
            </div>
          </div>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Create room"/>
        </div>
      </div>
    </PhoneS>
  );
}

function RoomInvite() {
  return (
    <PhoneS label="05 · Invite · share sheet" caption="QR + link + native share">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Invite to Bali Trip" leading={<CloseBtn/>}/>
        <div style={{flex:1, padding:'20px 20px 80px', display:'flex', flexDirection:'column', alignItems:'center', textAlign:'center', fontFamily:FONT}}>
          <div style={{width:200, height:200, borderRadius:16, background:T.surface, border:`1px solid ${T.bSubtle}`, padding:14, display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
            <Ico d={icons.qr} size={160} stroke={T.primary} sw={1.2}/>
          </div>
          <div style={{marginTop:18, fontSize:18, fontWeight:600, color:T.primary, letterSpacing:-0.1}}>Scan to join</div>
          <div style={{fontSize:13, color:T.secondary, marginTop:6, maxWidth:240}}>Anyone in the room can scan this QR. Code resets when removed.</div>
          <div style={{marginTop:20, width:'100%', padding:'12px 14px', background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, display:'flex', alignItems:'center', gap:10}}>
            <div style={{flex:1, fontSize:13, color:T.primary, fontFamily:MONO, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>loit.app/r/bali-trip-x4f9</div>
            <span style={{fontSize:13, fontWeight:600, color:T.brand}}>COPY</span>
          </div>
          <div style={{marginTop:14, display:'flex', gap:10, width:'100%'}}>
            <LoitButton size="m" variant="secondary" label="Share via app" fullWidth/>
          </div>
          <div style={{marginTop:12, padding:10, background:T.muted, borderRadius:10, fontSize:11, color:T.tertiary, textAlign:'left', width:'100%'}}>Free plan · up to 3 members per room. <span style={{color:T.brand, fontWeight:600}}>Upgrade for unlimited →</span></div>
        </div>
      </div>
    </PhoneS>
  );
}

function RoomsArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="H · Rooms" title="Multiplayer expense tracking — without becoming a chat app" subtitle="List · Feed (with color identity + presence) · Balances + settle · Create · Invite (QR)."/>
      <ScreensGrid>
        <RoomsList/>
        <RoomDetail/>
        <RoomBalances/>
        <RoomCreate/>
        <RoomInvite/>
      </ScreensGrid>
    </div>
  );
}

Object.assign(window, {RoomsArtboard});
