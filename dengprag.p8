pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--todo
--add food collision
--fix p1Xp2
--lift arriving next level
--test phone(ok?)
--map blocks throws error lvl 2
--drawing order
--enemies
  --tornado
  --bees
  --paquitas
  --claudia
--items themselves

--find if something is still in portuguese
--drop developing tools tab


coordc=split"-1,1,0,0,1,1,-1,-1"
coordl=split"0,0,-1,1,1,-1,-1,1"
clr=split"1,13,12,9"
nm=tonum

function _init()

 blink=false
 t=0
 --★
 msg={} 
 cls()

? 'starting game'
 stg={}
 for i=1,6do
  add(stg, gen_brd(i))
 end
? 'good game!'

 praga,dengue=nplayer(1),nplayer(32)
 --p2,p1=dengue,praga
 p1,p2=dengue,praga
 p={p1,p2}
 --p={p1}-- p2.x=-20
 pn=#p

 split_screen=false

 drw_stage(p1) 
 _drw=_drw_game
 _upd=_upd_game
end

function nplayer(sp)
 local s=stg[1]
 
 local x,y=s.cols\2,s.lins\2
 
 if(sp==1) x-=2
 
 return 
 {x=x*8,y=y*8,
 sp=sp,--sprite
 d=4,  --direction
 fal=false,
 visible=true,
 lv=3,--lives
 h=3, --health
 mh=5,--max health
 s=2, --speed
 sx=1,--speed mult
 i={},--itens
 cr=3,--collision radius
 cx=0,cy=0,
 c=0,--column
 l=0,--line
 bucks=0,
 dead=false,
 deadani=false,
 stg=s,
 selitem=0,
 ❎=false,
 upd=function(self)
  self.cx=self.x+3
  self.cy=self.y+15
  self.c=self.x\8
  self.l=(self.y+8)\8
  --☉
  self.fal=self.stg.brd[self.c+coordc[self.d]][self.l+coordl[self.d]].typ==1
 end,
 h_gain=function(self,n)
  n=n or 1
  local _ENV=self
  h+=n
  if(h>mh)lv+=1 h=mh
 end,
 h_loss=function (self,n)
  n=n or 1
  local _ENV=self
  h-=n
  if h<=0 then
   deadani=true
   lv-=1
   if lv<=0 then
    dead=true
   else
    h=mh
   end
  end
 end} 
end

function move_pl() 
 for i=0,3 do
  for j=1,pn do 
   if p[j].visible or i==3then
    local spd=p[j].s*p[j].sx
    --diagonals
    if(count({5,6,9,10},btn())>0)spd*=.7
    if btn(i,j-1) then
     p[j].d=i+1
     p[j].x+=spd*coordc[i+1]
     p[j].y+=spd*coordl[i+1]
    end
    if(i==3)p[j].visible=true
   end
  end
 end
end
-->8
--functions
function dice(lado)
 return flr(rnd(lado))+1
end

function bcomp(sig,match,mask)
 local mask=mask and mask or 0
 return bor(sig,mask)==bor(match,mask)
end

function copylist(l)
 local c={}
 for k,v in pairs(l)do
  c[k]=v
 end
 return c
end

function rotate(sp,mode,dx,dy,w,h,t)
 -- mode 0: clockwise 90
 -- mode 1: clockwise 270
 -- mode 2: mirror + clockwise 90
 -- mode 3: mirror + clockwise 270  
 -- dx,dy: screen position
 -- w,h: sprite width and height (1 if not specified) 
 -- t: transparent
 w,h,t=w or 1,h or 1,t or 0
 w,h=w*8-1,h*8-1
 local sx=sp%16*8
 local sy=(sp\16)*8
 local ya,yb,xa,xb=0,1,0,1
 
 if mode==0 then
  ya,yb=h,-1
 elseif mode==1 then
  xa,xb=w,-1
 elseif mode==2 then
  ya,yb,xa,xb=h,-1,w,-1
 end
 
 for y=0,h do
  for x=0,w do
   local c=sget(x+sx,y+sy)
   if(c!=t)pset((y-ya)*yb+dx,(x-xa)*xb+dy,c)
  end
 end
end

local function valid_xy(p,commit)
 local ok,c,l=false
 local s=p.stg
 repeat
  c,l=dice(s.cols),dice(s.lins)
  ok=(s.ibrd[c][l]==0)
 until ok
 if(commit)s.ibrd[c][l]=1
 
 return c*8,l*8
end


function collision(a,b,d)
 if(d==nil)d=a.cr+b.cr

 local dx=(b.cx or b.x)-(a.cx or a.x)
 if(dx>d)return false

 local dy=(b.cy or b.y)-(a.cy or a.y)
 if(dy>d)return false
--+rapido?
 return(abs(dx*dx+dy*dy)<=d*d)

--mais lerdo?
--[[local ang = atan2(dx,dy) -- -0.50
 return (abs(dx) <= abs(d*cos(ang)) and
         abs(dy) <= abs(d*sin(ang)))]]

end


function hitbox(p,o)
 local _ax,_ay,_ad=
  flr(p.cx-p.cr)
 ,flr(p.cy-p.cr)
 ,p.cr*2
 
 local _bx,_by,_bw,_bh=
  min(o[1],o[3])
 ,min(o[2],o[4])
 ,abs(o[3]-o[1])
 ,abs(o[2]-o[4])

 return not(
 _ay>_by+_bh or
 _by>_ay+_ad or
 _ax>_bx+_bw or
 _bx>_ax+_ad)
end

function sort(n)
 for i=1,#n do
  local j=i
  while j>1and n[j-1]>n[j]do
   n[j],n[j-1]=n[j-1],n[j]
   j-=1
  end
 end
end

function dist(a,b)
 return 
 sqrt(((b.cx or b.x)-(a.cx or a.x))^2+
      ((b.cy or b.y)-(a.cy or a.y))^2)
end

-->8
--level gen
function gen_brd(n)

 local size=split"1,1.2,1.4,1.5,1.7,1.9,2"

 local function valid_xy(commit)
  local ok,c,l=false
  repeat
   c,l=dice(cols),dice(lins)
   ok=(--brd[c][l].sig==0b11111111 and
       --brd[c][l].typ==2 and
       ibrd[c][l]==0)
  until ok
  if(commit)ibrd[c][l]=1
  return c*8,l*8
 end

 local function create_colblk(x,y,x1,y1)
  add(colblk,{x,y,x1,y1})
 end

 local f=size[n]
 local minarea=flr(64*f)
 local maxarea=minarea*10
 cols  =flr(32*f)
 lins  =flr(32*f)

 local seeds={}
 local area,space,
       earth,seed=0,1,2,3
 
 --board
 --item board
 brd,ibrd={},{}
 for c=0,cols do
  brd[c],ibrd[c]={},{}
  for l=0,lins do
   brd[c][l]={typ=space,val=0}
   ibrd[c][l]=0
  end
 end

? "stage " .. n
 --plant
 add(seeds,{c=cols/2,l=lins/2})
 for i=2,2+dice(5)do
  add(seeds,{c=3+dice(cols-6)
            ,l=3+dice(lins-6)})
 end

 area=#seeds
 --spread
 repeat
  --new seed
  local nseeds={} 
  for s in all(seeds) do
   for i = 1,8 do 
    if dice(4) == 1 then
     local nc=s.c+coordc[i]
     local nl=s.l+coordl[i]

     if nc==mid(2,nc,cols-3) and
        nl==mid(3,nl,lins-3) and
        maxarea> area then
      if brd[nc][nl].typ==1 then
       add(nseeds,{c=nc,l=nl,val=1})
       area+=1
      else
       brd[nc][nl].val+=1
      end
     end
    end
   end
   
   brd[s.c][s.l]={typ=2,val=1}
   del(seeds,s)
  end

  seeds=nseeds
  --throw a new seed, if necessary
  if #seeds==0 and area<minarea then
   local ok,tries=false,10
   repeat 
    tries -=1
    local nc,nl=3+dice(cols-6),3+dice(lins-6)
    if brd[nc][nl].typ==1 then
     add(seeds,{c=nc,l=nl})
     ok=true
    end
   until ok or tries<=0
  end
 
  for i=1,#seeds do
   brd[seeds[i].c][seeds[i].l].typ=3
  end
 until #seeds<=0

 --sig 
 for l=0,lins do
  for c=0,cols do
   local sig,t=0,brd[c][l]
   if l==mid(1,l,lins-1) and
      c==mid(1,c,cols-1) then
    for i=1,8do
     local digit=0
     if(brd[c+coordc[i]][l+coordl[i]].typ~=space)sig=bor(sig,shl(1,8-i))
    end
   end
   if(t.typ==1 and sig~=255)sig=0
   t.sig=sig
  end
 end

? "item board"
 for l=0,lins do
  for c=0,cols do
   if brd[c][l].typ==space then
    ibrd[c][l]=1
   elseif brd[c][l].sig~=255 then
    ibrd[c][l]=1   
   end
  end
 end 


?'food'
 food={}
 for i=1,ceil(n*1.5) do
  local x,y=valid_xy(true)
  add(food,
  {
   x=x,
   y=y,
   cx=x+3,
   cy=y+5,
   cr=4,
   sp=87+dice(5),
   poison=dice(10)==1
  })
 end


?'collision'
 --collision blocks
 colblk={}
 
?'map blocks'
 --map blocks
 local mblk={}
 local tam=8--max(16*(16/cols),4)
 local f=tam*(128/cols)
 for c=0,(cols/tam)-1do
  for l=0,(lins/tam)-1do
   add(mblk,
       {c*f+1
       ,l*f+1
       ,c*f+f 
       ,l*f+f 
       ,14+(l%2)})    
  end
 end
? 'phone'
 --phone
 local phone={x=0,
        y=0,
        ringing=false,
        visible=false,
        age=0,
        last_call=360,
        sp=16,
        cr=3}

?'items'
 --items 
 --todo:
 --[[- define item num per stage
     - items themselves]]
 local items={}
 for i=1,n*10 do

  local x,y=valid_xy()--brd)

  add (items,
       {x=x,
       y=y,
       sp=rnd({15,31,47,63,62}),
       pl=rnd({{},{7,14,2,12},{3,11,5,14},{12,9,1,10}}),
       cx=x+3,
       cy=y+5,
       cr=4})
 end

?'lift'
 --lift 
 local lift={}
 do
	 local ok,tries,c,l=false,10
	 repeat
	  tries+=1
	  c,l=valid_xy(false)
	  c/=8 l/=8
	  if l<lins+1 then
 	  --★
	   if brd[c][l+3].sig==255 and
	      brd[c][l+3].typ==2 and
	      ibrd[c][l+3]==0 and
	      brd[c][l+2].sig==255 and
	      brd[c][l+2].typ==2 and
	      ibrd[c][l+3]==0
	    then
	    ok=true
	   end
	  end 
	 until ok or tries<=0
  lift={c=c,l=l,x=c*8,y=l*8,open=false,age=0,cr=8}
  create_colblk(lift.x-10,lift.y-15,lift.x+10,lift.y-8)
  create_colblk(lift.x-12,lift.y-15,lift.x-8,lift.y)
  create_colblk(lift.x+7,lift.y-15,lift.x+11,lift.y)
 end

?'money'
 --money
 local money={}
 for i=1,n do
  local x,y=valid_xy()
  add(money,{x=x,y=y,cr=2,cx=x+4,cy=y+4})
 end
?'tree'
 --tree
 local tree={}
 for i=1,n do
  local x,y=valid_xy()
  add(tree,{x=x,y=y,cr=4})
 end

 local shorties={}
 for i=1,n do
   local x,y=valid_xy()
  add(shorties,
{
x=x,
y=y,
h=1,
sp={77,78,79},
spsleep={75,76},
sleep=true,
sr=32,--sleep range
ar=16,--attack range
cr=3,
cx=x+4,
cy=y+4,
dx=0,dy=0,
--behav={'slp'}
cb=1,
s=.5,
ang=0,
wage=0,
tage=0,
upd=function(self)
 self.cx=self.x+4
 self.cy=self.y+4
end,
})
end

 return
	{lvl=n,
brd=brd,
ibrd=ibrd,
cols=cols,
lins=lins,
mblk=mblk,
phone=phone,
items=items,
lift=lift,
colblk=colblk,
money=money,
tree=tree,
shorties=shorties,
food=food}
end

-->8
--draw

--★
--match=split "0b11010000,0b00010000,0b00100000,0b01000000,0b10000000,0b10000000,0b01010000,0b10100000,0b01100000,0b11000000,0b00000000"
--mask=split"0b00001111,0b00001111,0b00001111,0b00001111,0b00000011,0b00011111,0b00001111,0b00001111,0b00001111,0b00101111,0b00001111"
match=split"208,16,32,64,128,128,80,160,96,192,0"
mask=split"15,15,15,15,3,31,15,15,15,47,15"
scn=split"82,87,86,70,71,69,68,67,66,65,83"

function _draw()
 cls()
 _drw()
 --★
 --[[for i=1,#msg do
  if (msg[i] != nil) ?msg[i],0, (#msg-i)*8,7
 end]]
end

function _drw_game()

 if pn==1 then
  camera(p1.x-63,p1.y-63)
	 map()
  drw_food(p1)
	 drw_items(p1)
	 drw_money(p1)
	 drw_phone(p1)
	 drw_lift(p1)
	 drw_tree(p1)
	 drw_player(p1)
	 drw_shorties(p1)
	 drw_stats(n)
 else
  if collision(p1,p2,65) then
   camera(((p1.x+p2.x)\2)-63,((p1.y+p2.y)\2)-63)
   map()
   split_screen = false  
   drw_food(p1)
		 drw_items(p1)
		 drw_money(p1)
		 drw_phone(p1)
		 drw_lift(p1)
		 drw_tree(p1)
		 drw_shorties(p1)
   drw_player(p1)
   drw_player(p2)
   drw_stats(n)
		 
  else
   split_screen = true  
   --p1
   camera(p1.x-63,p1.y-30)
   clip(0,0,128,63) 
   map()
   drw_food(p1)
   drw_items(p1)
		 drw_money(p1)
		 drw_phone(p1)
		 drw_lift (p1)
		 drw_tree (p1)
   drw_shorties(p1)
   drw_player(p1)
   drw_player(p2)
		 drw_stats(1)
   --p2 
   camera(p2.x-63,p2.y-83)
   clip(0,64,128,128)
   map()
   drw_food(p2)
   drw_items(p2)
		 drw_money(p2)
		 drw_phone(p2)
		 drw_lift(p2)
		 drw_tree(p2)
   drw_shorties(p2) 
   drw_player(p2)
   drw_player(p1)
		 drw_stats()
 
  end
 end
 --★
 --drw_blk(p1)
 for i=1,#msg do
  if (msg[i] != nil) ?msg[i],p1.x-63, p1.y-63+(#msg-i)*8,7
 end  
end

f=0
y=127
animode=4
function _drw_lift()
 local ani=animode
 local rad,spd=36,10
 local lift = p1.stg.lift
 f-=1/spd
 for i=0,127do
  for j=0,127do
  local ir,jr=i/rad,j/rad
   pset(i,j,
    (ani==1 and
    sin(ir)+cos(jr)
    or ani==2 and
    sin(ir)*cos(jr)
    or ani==3 and
    sin(ir)/cos(jr)
    or ani==4 and
    cos(jr)
    or sin(ir))
    +f)
  end
 end

 y-=2
 x=65
 lift.x=x
 lift.y=y
 drw_lift(p1)
 
 if y<32 then
  drw_stage(p1) 
  _drw=_drw_game
  _upd=_upd_game
 end
end

cexc={}
cani=0
function _drwphone()
 drw_map(p1)
end

function drw_stage(s)
 local m=s.stg
 for l=0,m.lins do
  for c=0,m.cols do
   local t=m.brd[c][l]
   local s,cr,sp=t.sig,t.typ==1,0
   if cr then
    if(s==0)sp=rnd(split"81,97,0,0,0,0,0,0,0")
    if(s==255)sp=98
   elseif s==0 then
    sp=83  
   elseif s==256 then
    sp=rnd(split"64,80,96")
   else
    for i=1,#match do
     if(bcomp(s,match[i],mask[i]))sp=scn[i]
    end
    if(sp==0)sp=rnd(split"64,80,96")
   end
   mset(c,l,sp)
  end
 end
end

function drw_items(s)
 item_ps=split"9,10,4,8"
 --presents
 for pr in all(s.stg.items) do
  --pallet swap
  for i =1,#pr.pl do
   pal(item_ps[i],pr.pl[i])
  end
  spr(pr.sp,pr.x,pr.y)
  pal()
 end  
end 

function drw_lift(s)
 local lift = s.stg.lift
 local x,y=lift.x,lift.y

 lift.age=max(lift.age-1,0)
 lift.open=not (lift.age==0)
 --back
 rectfill(x-8,y-22,x+6,y,12)
 fillp(▥)
 rectfill(x-8,y-22,x+6,y,6)
 fillp()
 --sliding doors
 rectfill(x-8,y-22,x-lift.age\10,y,9)
 rectfill(x+1+(lift.age\10),y-21,x+7,y,9) 
 
 if not lift.open then
  line    (x,y-17,x,y,7)
  fillp(…)
  line    (x,y-17,x,y,12)
  fillp()
 end
 
 spr (127,x-11,y-7)
 spr (127,x-11,y-15)
 spr (111,x-11,y-22)
 spr (111,x+4, y-22,1,1,true)
 rotate(127,0,x-4,y-23)
 spr (127,x+4,y-6,1,1,true)
 spr (127,x+4,y-14,1,1,true)
 
--pset(lift.x,lift.y,8+nm(blink))
--circ(lift.x,lift.y,lift.cr,7)
end

function drw_tree(s)
 local function _tree(x,y)
  local y1,y2,y3=y-30,y-14,y-22
  local x1,x2,x3=x-12,x-4,x+4
  pal(13,3)
  pal(4,11)
  pal(1,10)
  --★
  spr(68,x1,y1)
  spr(66,x1,y2)
  spr(64,x1,y3) 
  spr(82,x2,y1) 
  spr(65,x2,y2) 
  spr(96,x2,y3) 
		spr(69,x3,y1)
		spr(64,x3,y3)  
		spr(67,x3,y2)
  pal()
  spr(125,x2,y-12,1,1,true,true)
  spr(125,x2,y-4)
  --pset(x,y,8+nm(blink))
  --circ(x,y,6)
 end

 for i in all(s.stg.tree) do
  _tree(i.x,i.y)
 end
end

function drw_money(s)
 for i in all(s.stg.money) do
  spr(14,i.x,i.y)
  --circ(i.cx,i.cy,3,8)
 end
end


function drw_food(s)
 for i in all(s.stg.food) do
  spr(i.sp,i.x,i.y)
 end
end

function drw_phone(s)
 local ph=s.stg.phone
 if(ph.visible) then
  pal(7,7-nm(blink))
  spr(ph.sp,ph.x,ph.y) 
  pal()
 end
end

function drw_player(p)
 --pset(p.x,p.y,12+tonum(blink))
 --pset(p.cx,p.cy,8+tonum(blink))
 --circ(p.cx,p.cy,p.cr,8)
 if(not p.visible)return
 if p.fal then
  spr(p.sp+7+nm(t%15>5),p.x,p.y,1,2,(t%15>10))
 elseif p.d==1 then
  spr(p.sp+2+(flr(t%15)/5),p.x,p.y,1,2,true)
 elseif p.d==2 then
  spr(p.sp+2+(flr(t%15)/5),p.x,p.y,1,2)
 elseif p.d==3 then
  spr(p.sp+5+nm(t%15>5),p.x,p.y,1,2,(t%15>10))
 elseif p.d==4 then
  spr(p.sp  +nm(t%15>5),p.x,p.y,1,2,(t%15>10))
 end
 
 --hitbox
-- rect(p.cx-p.cr,p.cy+p.cr,p.cx+p.cr,p.cy-p.cr,8) 
end

function drw_stats(n)
 local function drw(x,y,p)
   local it={11,10,62} 
   rectfill(x,y,x+69,y+7,1)

  	--lives
   print("\*" .. p.lv .. "★",x+1,y+1,8)
 
   --healthbar
   local hb=25+flr((p.h*(25/p.mh)))
   rectfill(x+25,y+1,x+50,y+5,7)
   rectfill(x+25,y+1,x+hb,y+5,9)
   spr(p.sp,x+53,y-1)
   print("$"..p.bucks,x+61,y+1)
   
   if(p==p2)x-=173 y-=5
   circfill(x+121,y+6,6,1)
   circfill(x+121,y+6,5,6)

   spr(it[p.selitem+1],x+118,y+2)
  end

 if pn==1 then
  drw(p1.x-63,p1.y-63,p1)
 else
  if split_screen then
   if n==1 then
    drw(p1.x-63,p1.y-30,p1)
   else
    drw(p2.x-5,p2.y+37,p2)
   end
  else
   local mx,my =((p1.x+p2.x)\2)-63
               ,((p1.y+p2.y)\2)-63
   drw(mx,my,p1)
   drw(mx+58,my+120,p2)
  end
 end
end

function drw_map(s)
 s=s or p1
 local m=s.stg
 local lift=m.lift
 cls()
 camera()

 local fct=8/(m.cols/16)
 for l=0,m.lins do
  for c=0,m.cols do   
   local _c=clr[m.brd[c][l].typ]
   --players
   if(p1.visible and c==p1.c and l==p1.l)_c=2
   if(pn>1 and p2.visible and c==p2.c and l==p2.l)_c=9
 
   rectfill(c*fct
           ,l*fct
           ,c*fct+fct
           ,l*fct+fct
           ,_c) 
  end
 end
--lift
 pal(7,blink and 12 or 7)
 spr(126,lift.c*fct,lift.l*fct)
 pal()
 --map blocks
 fct=8*(128/m.cols)
 for b in all(m.mblk) do 
  rectfill(unpack(b))
 end
end

--todo
function drw_shorties(p)
 for i in all(p.stg.shorties)do

  if i.sleep then
   spr(i.spsleep[1+nm(t%80>40)],i.x,i.y)
   print ('Z',i.cx-2,i.y-8+nm(t%20>10),7)
   print ('z',i.cx,i.y-10+nm(t%15>10),7)
   print ('z',i.cx+2,  i.y-12+nm(t%30>15),7)
  else
   spr(i.sp[1+flr((t%15)/5)],i.x,i.y+nm(t%10>5),1,1,
   (t%9>3)
   )
  end
 
--  pset(i.cx,i.cy,8+nm(blink))
--  circ(i.cx,i.cy,i.cr,8)
--  line(p1.x,p1.y,i.x,i.y,9)
--  circ(i.cx,i.cy,i.sr,10)
 end
end


--todo
function drw_paquitas()
pal(8,12)
spr(41+flr((t%15)/5),p1.x-14,p1.y-4,1,2,(t%15>7))
spr(41+flr((t%15)/5),p1.x-6,p1.y-4,1,2,(t%15>7))
pal()
spr(41+flr((t%15)/5),p1.x-10,p1.y,1,2,(t%15<7))
end

--todo
function drw_ship()
 spr(118,p1.x-26,p1.y+4)
 spr(102,p1.x-26-flr((t%24)/6) ,p1.y+4)
 spr(102,p1.x-26+flr((t%24)/6) ,p1.y+4,1,1,true)
 spr(100,p1.x-30,p1.y,2,2,blink,false)
end

-->8
--update

function _update()
 t+=1
 blink=not blink
 _upd()
end

function _upd_map()
 local i=0
 for _p in all(p) do
  if btnp(❎,i) then
   _p.❎ = not _p.❎
   _drw = _drw_game
   _upd = _upd_game
  end
  i+=1
 end
end


function _updphone()
 cani-=1 
 local s=p1.stg
 
 for c in all(cexc)do
  local b = s.mblk[c]
  if b[1]<=b[3] then
   for i = 1,2 do
    b[i]+=.4
    b[i+2]-=.4
   end
  end
 end
 
 if cani<=0 then
  for c=#cexc,0,-1 do
   deli(s.mblk,c)
  end
  cexc={}
  _drw=_drw_game
  _upd=_upd_game
 end
end

function _upd_game()
 local i=0
 for _p in all(p) do

  if btnp(❎,i) and _p.selitem==0 then
    _p.❎=not _p.❎1
    _drw=_p.❎ and drw_map or _drw_game
    _upd=_upd_map
  end
 
  _p.sx=1
  if btn(❎,i) then
   --chinelo
   if(_p.selitem==1)_p.sx=_p.s*0.3
  end
  
  if btnp(🅾️,i) then
   _p.selitem=(_p.selitem+1) % 3
  end
  i+=1
 end

 --player
 move_pl()
 for _p in all(p) do
  _p:upd()
 end

 
 local lift_pop=0
 --loop
 for _p in all(p) do
  local v=(_p.s*_p.sx)*1.2
  local s=_p.stg  
  local function backoff()
   _p.x-=coordc[_p.d]*v
   _p.y-=coordl[_p.d]*v
  end
  
  --map blocks
  local fct=(s.cols*8)/128
  for b in all(s.mblk) do
   if _p.cx>=b[1]*fct and _p.cx<=b[3]*fct and
      _p.cy>=b[2]*fct and _p.cy<=b[4]*fct then
    del(s.mblk,b)
   end
  end

	 --telephone
	 local p=s.phone
	 if p.ringing then
	  p.age-=1 
	  if(p.age%160==0)sfx(10)  
	  if p.age<=0then
	   p.ringing=false
	   p.visible=false
	  end
	 else
	  ringring(_p)
	 end
	 
  --tree
  for i in all(s.tree)do
   if(collision(_p,i))backoff()
  end
  
  --hitbox
  for i in all(s.colblk)do
   if(hitbox(_p,i))backoff()
  end
  
  --items
  for i in all(s.items)do
   if(collision(_p,i))then
    del(s.items,i)
   end
  end

  --money
  for i in all(s.money)do
   if(collision(_p,i))then
    _p.bucks+=1
    del(s.money,i)    
   end
  end

  --shorties sleep
  for i in all(s.shorties)do
   i:upd()
   if i.sleep then
	   if dist(p1,i)<i.sr then
	    i.sleep=false
	    
 	   i.ang=atan2(_p.x-i.x,_p.y-i.y)
	    i.dx+=cos(i.ang)*i.s
	    i.dy+=sin(i.ang)*i.s
	   end
   end
   if not i.sleep then
    i.x+=i.dx
    i.y+=i.dy
   end
  end
  
  --lift
  local lift=s.lift  
  if collision(_p,lift) then
   if _p.cy-1 < lift.y then
    if(not _p.visible)lift_pop+=1
    lift.open=false
    _p.d=4
    _p.visible=false
    lift_pop+=1
    if(lift_pop==pn and lift.age<=0)next_level()
   else
    lift.age=min(lift.age+10,80)
    lift.open=true    
    _p.visible=true
   end
  end

  --collision pXp
  if pn==2 then
   local v=p1.s*p1.sx*1.2
   if collision(p2,p1) and
      p1.visible and 
      p2.visible then
    p1.x-=coordc[p1.d]*v
    p1.y-=coordl[p1.d]*v
    p2.x-=coordc[p2.d]*v
    p2.y-=coordl[p2.d]*v
   end
  end

  --phone collision
  local phone = s.phone
  if phone.visible and #s.mblk>0 then
   if(collision(_p,phone)) then
    phone.visible = false
    phone.age = 0
    sfx(11)

    for t=1,1+dice(4) do
     local i=dice(#s.mblk)
     add(cexc,i)
    end
    sort(cexc)
    
    cani=60
    _drw=_drwphone
    _upd=_updphone   
   end
  end 
 end
end

function next_level()
 camera()
  p1.stg.lvl+=1
  p1.stg=stg[p1.stg.lvl]
  _drw=_drw_lift
end
-->8
--items

function ringring(p)
 --+55(11)236-0873
 local ph=p.stg.phone

 if(#p.stg.mblk<=0)return
 if t - ph.last_call> 3600 and 
    dice(10)==1 and
    not ph.ringing then
  do
   local _x,_y=valid_xy(p)
   local _ENV=ph
   x=_x
   y=_y
   cx=x+3
   cy=y+4
   ringing=true
   visible=true
   age=600
  end
  ph.last_call=t
  sfx(10)
 end
end
-->8
--tools for developing(delete all)
function desclist(l,f)
 for k,v in pairs(l)do
  if type(v)~="table"then
   printh('  '..k..': '..v ,f)
  else
   printh('' ,f)
   printh(k..'=',f)
   desclist(v,f)
  end
 end
end
function tobin(n)
 local bin=""
 for i=7,0,-1 do
  bin..=n\2^i%2
 end
 return bin
end
function log(m)
 add(msg,m)
 if #msg > 5 then
  deli(msg,1)
 end
end
function log(m)
 add(msg,m)
 if(#msg>5)deli(msg,1)
end


--★
function drw_blk(p)
 --fillp(░)
 for i in all(p.stg.colblk) do
  rect(--fill(
  --unpack(i)
  i[1],i[2],i[3],i[4]
  --,8)
  ,11)
 end
 --fillp()
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000002220000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000022922000000000000000000000000000000000000808000
0070070000000000000000000000000000000000000bb9000000000000000000000000000000000002e2e20009ff000000000000000000000bbbbbb000080000
00077000009bb90000000000000bb9000000000000bbbbb0009bb9000000000009bb90000009bb900e222e0009f8ff90000000000000000000bb33b009989940
0007700000bbbb00009bb90000bbbbb00000bb900bbbff0000bbbb00009bb9000bbbb000000bbbb00222220009b3ff40000000000000000000333b0009989940
007007000bffffb000bbbb000bbbff00000bbbbb0bbbf5000bbbbbb000bbbb00bffffb0000bffffb0222200004448f4000000000000000000033bb0009989940
000000000b5ff5b00bffffb00bbbf50000bbbff000bbfc000bbbbbb00bbbbbb0b5ff5b0000b5ff5b0222200000004440000000000000000000300b0009989940
0000000000bccb000b5ff5b000bbfc0000bbbf500000000000b66b000bbbbbb00b8eb000000b88b0002220000000000000000000000000000000000000000000
600e00000003300000bccb00000b3000000bbfc0000b30000003300000b66b000000000000000000000000000000000000000000000000000000000000000000
06e7e0000039930000399300003390000003900000339000000333000003300000039300a0393000000000000000000000000000000000000000000000808000
0e777e00a3bbbb30a3bbbb300b3abb000b3abb000b3abb000a33b330a3333300003bbb3003bbb3a0000000000000000000000000000000000000000000080000
0be7e5e00399993a0399993a0333a900033ab90003a3b900003b9b3a033bb3a00039993a0399930000000000000000000000000000000000000000009a98a9a4
00be5e5e03bbbb3003bbbb300b339b000b339b000b339b000033b33000b99b000a3bbb3003bbb3000000000000000000000000000000000000000000a9a89a94
000be5eb003333000033330000333000003330000033300000033300003bb300000333000033300000000000000000000000000000000000000000009a98a9a4
0000beb000a00a0000300a0000a0a00000a00a0000a0a000000a0a0000a00300000a003000a003a00000000000000000000000000000000000000000a9a89a94
00000b00003003000000030003003000003003000030300000030300003000000003000000000000000000000000000000000000000000000000000000000000
00000000004440000044400000044400000000000000000000444000000000000004440000000000000000000000000000000000000000000000000000000000
00444000406660404066604004066604000444000044400040666040004440000406660400888000000000000088800000000000000000000000000000000000
40666040044444000444440000444440040666044066604004444400406660400044444000888000008880000088800000000000000000000000000000000000
044444000fffff000effff0000effff000444440044444000eeeee000444440000fffff000999000008880000099900000000000000000000000000000808000
0fffff000fcfcf000e5fcf0000e5fcf000effff00eeeee000eeeee000fffff0000fcfcf00acfca00009990000acfca0000000000000000000000000000080000
0fcfcf000e585e000e5e580000e5e58000e5fcf00eeeee000eeeee000fcfcf0000e585e00afffa000acfca00fafffa0f0000000000000000000000009a98a9a4
0e585e00055555000e55550000e5555000e5e5800eeeee0000eeee000e585e000055e550000000000afffa00f00000f0000000000000000000000000a9a89a94
05555500009c90000009c00000009c0000e5555000eeee0000999000055e550000000000098989000989890f0989890000000000000000000000000000000000
00aaa00000aaa00000033000000330000300330000aaa00000aaa00000aaa00090aaa000f08880f0f08880f00088800000000000000000000000000000800000
0f999f909f999f000309900003099900333099000f999f90933333000f999f900f999f00f089800f0f8980000089800000000000000000000000000000080800
90aaa00000aaa09033afaa0033afaa00333afaa0903a30000333339090aaa00090aaa09000666000006660000066600000000000000000000000808000488000
0f999f909f999f00339799003399790003397990033333909f393f000f999f900f999f000077700000777000007770000000000000000000808008000498a400
90aaa00000aaa090030fa000030fa0000030fa00903a300000aaa09090aaa00000aaa09000f0f00000f0f00000f0f0000000000000000000080aa8a949a89a40
00999000009990000097900000997000000979000099900000999000009990000099900000707700007070000070770000000000000000009894a8a94a98a940
00a0a0000090a00000a0a00000a00a00000a0a0000a0a0000090a00000a0090000a0000000700070007070000070007000000000000000009894a8a904a89400
00909000000090000300300000300300000303000090900000009000009000000090000007700000077077000770000000000000000000009894000000484000
dddddddddddddd1dd1dddddddddddddd000000000000000000000dddddd0000000000000000000000aa000000000000000000000808880800088800000888080
dddd8ddddedddddd4dddddddddddddd4000000000000000000dddddddddddd000000000000000000abba00000000000000000000088889000888890008888900
dddddddddddddddd44dddd1ddddddd4400000dddddd000000ddddddddeddddd00000000000000000abba00000000000000888000004f4000804f4080804f4000
dddddddddddddddd044deddddd1dd9400000dddddded000004dd1dddddd1ddd000000000000000000aa00000008880000888890000fff0f0f0fff00000fff0f0
ddd1dddddddddddd0494dddddddd44400dddddddddddddd004dddddddddddd400000000000000000000000000888890008fff8000fe2ef000fe2ef000fe2ef00
deddd8dddddddddd00044dddddd44000dddddd1ddddddddd004dddddddddd4000000000000000000000000008f888f800fe2ef00f0eee00000eee0f0f0eee000
dddddddd444494440000444444000000ddeddddddddddddd0004944444494000000000000000000000000000f0eee0f0f0eee0f000aaa00000aaa00000aaa000
dddddddd449449490000000000000000ddddddddddddddd100000000000000000000000000000000000000000aa0aa000aa0aa000000a00000a0a00000a00000
dddddddd00000000dd0dd00d00dddd0000000000000000004dd1ddd4000000000044440004900000000000000000000000000000000000000000000000000000
dddddddd00000000dddddddd0dddddd0000000000000000004ddddd400000000044444404900000000999900000ee0000000b000000000000000000000000000
dddd6ddd00000000ddddddddd5dddedd000000000000000004dddd9400ddd000444ff444af0000000944449060a99e0600030000000000000000000000000000
d1dddddd00000000dddddddddddde6ed0000000000000000004ddd400ddddd0044499444aaf000009449944906caa96000888000000000000000000000000000
ddddddfd00000000ddd1dddddddddedd0000000000000000004494400d5dddd0f444444f9aaf00009494494965ecca5608788800000000000000000000000000
dd8ddddd00000600deddd8ddddddd1dd000000000000000000044000dddddddd9f4444f949aafff094494990d08eec0d08688800000000000000000000000000
dddddddd00000000dddddddd04ddddd0000000000000000000000000dddddddd09ffff90049aaaaf094449000008800008888200000000000000000000000000
dddddddd00000000dddddddd00494400000000000000000000000000dddddd1d0099990000499990009990000000000000222000000000000000000000000000
dddddddd000000004000000900000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000009999
dddddddd00000000000000000000000000000eeeeee0000002ee0000000000000000000000000eeeeee000000000000000000000000000000000000000992e22
d5dddedd00000000000000000000000000008989898a00002ee80000000000000000000000008989898a0000000000000000000000000000000000000922eae2
dddde6ed000000000000000000000000000eeeeeeeeee0002e8800000000000000000000000eeeeeeeeee0000000000000000000000000000000000009222e22
dddddedd00000000000000000000000000eeee2222eeee002ee80000000000000000000000eeee2222eeee00000000000000000000000000000000009e2e2244
ddddd1dd000600000000000000000000008ee200002ee80002ee00000000000000000000008ee2eeee2ee8000000000000000000000000000000000092a22400
dddddddd000000000000000e00000000088e20000002e88002ee00000000000000000000088e2ee88ee2e880000000000000000000000000000000009e2e4000
dddddddd00000000d000000d00000000eeee20000002eeee000000000000000000000000eeee2e8888e2eeee0000000000000000000000000000000092224000
00000000000000000000000000000000eeee20000002eeee002222000000000000000000eeee2ee88ee2eeee0000000000000000044444400099990092224000
000000000000000000000000000000000eeee200002eeee0029a9a2000000000000000000eeee2eeee2eeee00000000000000000049449400922229092e24000
00000000000000000000000000000000000ee200002ee0002dddddd20000000000000000000ee2eeee2ee000000000000000000004494440924444299eae4000
000000000000000000000000000000000098898989899800255aa552000000000000000000988989898998000000000000000000094949409247c42992e24000
0000000000000000000000000000000000098989898980002d9aa9d200000000000000000009898989898000000000000000000009444940924c742992224000
000000000000000000000000000000000000eeeeeeee00000299992000000000000000000000eeeeeeee00000000000000000000049449409247c4299e2e4000
0000000000000000000000000000000000000000000000000259952000000000000000000000000000000000000000000000000040940040924c742992a24000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404044444444449e2e4000
