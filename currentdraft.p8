pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
  -- possible states: MENU, GAMEPLAY, GAMEOVER
  STATE="MENU"
  spritesize=8
  LEVEL=0
  FOUND_SNACK=false
  FOUND_CAT=false
  LEVEL_TO_SNACK = { [0] = {
                         snack={ s=57, x=0, y=96 },
                         cat={ s=22, x=16, y=48 }
                       },
                     [1] = {
                         snack={ s=15, x=240, y=280 },
                         cat={ s=80, x=200, y=184 }
                     },
                      [2] = {
                         snack={ s=15, x=240, y=280 },
                         cat={ s=80, x=200, y=184 }
                     },
                   }
  CAT_NAME={[0]="Horatio",[1]="Joe Buck",[2]="Georgia"}
  minx=0
  miny=0
  maxx=248
  maxy=512
  min_cam_y=0
  max_cam_y=388
  max_cam_x=maxx/2
  MAX_DY=5 
  startx=3
  starty=440
  gravity=0.25
  friction=0.80
  player={ 
    x=startx,
    y=starty,
    s=19,
    w=8,
    h=8,
    flp=false,
    dx=0,
    dy=0,
    max_dx=2,
    max_dy=3,
    acc=0.25,
    boost=3.8,
    anim=0,
    running=false,
    jumping=false,
    landed=false,
    dashing=false,
    candash=true,
    dying=false,
    runf=0,
    idlef=0,
    direction=1,
    dashtick=0,
    dashframe=-1,
    dieframe=0
  }
  dashtrail=24
  miny=player.y-5 -- todo: needs thought
  tick=0
  fs=false
  cam_x=player.x-64+player.w/2
  cam_y=player.y-64+player.w/2
end

function _update()
  if STATE=="MENU" then return menu_update() end
  if STATE=="GAMEPLAY" then return gameplay_update() end
  -- TODO: game over
end

function gameplay_update()
  if FOUND_CAT and (time()-FOUND_CAT_TIME) > 3 then
    LEVEL+=1
    reset_player_location()
    FOUND_CAT=false
    FOUND_SNACK=false
  end
  if not FOUND_CAT then player_update() end
  player_animate()
  camera_update()
end

function menu_update()
  if btnp(4) then
    -- gus
    player.ws={[0]=20,[1]=36,[2]=20,[3]=4}
    player.is={[0]=20,[1]=52}
    player.jump_s=100
    player.dash_s=116
    player.die_s=99
    STATE="GAMEPLAY"
  elseif btnp(5) then
    player.ws={[0]=19,[1]=35,[2]=19,[3]=3}
    player.is={[0]=19,[1]=51}
    player.jump_s=33
    player.dash_s=32
    player.die_s=49
    STATE="GAMEPLAY"
  end
end

function _draw()
  cls()
  if STATE=="MENU" then return menu_draw() end
  if STATE=="GAMEPLAY" then return gameplay_draw() end
end

function gameplay_draw()
  local map_x = LEVEL*32
  map(map_x, 0)
  if FOUND_SNACK then
    local s = LEVEL_TO_SNACK[LEVEL].snack
    spr(s.s,s.x,s.y)
  end
  if not FOUND_SNACK then
    local c = LEVEL_TO_SNACK[LEVEL].cat
    spr(c.s,c.x,c.y)
  end
  -- player
  spr(player.s,player.x,player.y,1,1,player.flp)
  if player.dashing and player.dashframe<8 then
    draw_dash_trail(player.x,player.y,player.dashframe,player.flp)
    player.dashframe+=1
  end
  if FOUND_CAT then
    local seconds=flr(time()-FOUND_CAT_TIME)+1
    for i=1,seconds do
      -- <3
      local x
      local y = player.y - 10 * i
      if i%2==0 then x = player.x-10 else x = player.x+10 end
      spr(50, x, y)
    end
    local name = CAT_NAME[LEVEL]
    print("You found "..name.."!", cam_x, cam_y+10, 9)
    if LEVEL<2 then 
      print("Let's go find "..CAT_NAME[LEVEL+1].."!", cam_x, cam_y+20, 9)
    end
    if catsound==nil then -- todo: this doesn't belong here and is gross
      sfx(0) catsound=true
    end
  end
end

function menu_draw()
  print("MAIN MENU", 10, 10)
  print("PRESS X TO START AS MOLLIE!", 10, 20)
  print("PRESS Z TO START AS GUS!", 10, 40)
  -- todo: character select
end

function camera_update()
  cam_x=mid(minx, player.x-64+player.w/2, maxx)
  if cam_x < 0 then cam_x=0 end 
  if cam_x > max_cam_x then cam_x=max_cam_x end
  cam_y=player.y-104+player.w/2
  if cam_y > max_cam_y then cam_y=max_cam_y end
  if cam_y < min_cam_y then cam_y=min_cam_y end
  camera(cam_x,cam_y)
end

function draw_dash_trail(x,y,frame,flp)
  local startx = nil
  if flp then startx=x+9 else startx=x-1 end
  
  for i=1,frame do
    local ny = y
    for j=8,14 do
      pset(startx,ny,j)
      ny+=1
    end
    if flp then startx+=1 else startx-=1 end
  end
end

function player_animate()
  if player.jumping then
    player.s=player.jump_s
  elseif player.dashing then
    player.s=player.dash_s
  elseif player.dying then
    player.s=player.die_s
    player.dieframe+=1
    if player.dieframe==8 then
      player.dieframe=0
      player.dying=false
      reset_player_location()
    end
  elseif player.running then
    if time()-player.anim>.1 then
      player.anim=time()
      player.s=player.ws[player.runf]
      player.runf=(player.runf+1)%4
    end
  else
    if time()-player.anim>.4 then
      player.anim=time()
      player.s=player.is[player.idlef]
      player.idlef=(player.idlef+1)%2
    end
  end
end

-- thanks nerdy teachers :D
function player_update()
  if player.dy < MAX_DY then
    player.dy+=gravity
  end
  player.dx*=friction

  if btn(0) then -- left
    player.dx-=player.acc
    player.running=true
    player.flp=true
    player.direction=-1
  end
  if btn(1) then -- right
    player.dx+=player.acc
    player.running=true
    player.flp=false
    player.direction=1
  end
  
  if btnp(5) and player.landed then
    player.dy-=player.boost
    player.landed=false
    --sfx(1)
  end

  if btnp(4) and player.candash then
    player.dashing=true
    player.candash=false
    player.dx+=player.direction*5
    player.dashtick=time()
  end

  if time()-player.dashtick>0.3 then
    player.dashing=false
    player.candash=true
    player.dashframe=0
  end

  -- check collision up and down
  if player.dy>0 then
    player.landed=false
    player.jumping=false
    
    if collide_map(player,"down",0) then
    -- if collide_map(player,"down",0) or collide_map(player, "left", 1) or collide_map(player, "right", 1) then
      player.landed=true
      player.dy=0
      player.y-=((player.y+player.h+1)%8-1)
      if player.candash==false then
        player.candash=true
        player.dashframe=0
      end
    elseif collide_map(player,"down",2) then
      player.dying=true
      return
    end
  elseif player.dy<0 then
    player.jumping=true
    if collide_map(player, "up", 1) then player.dy=0 end
  end

  -- check collision left and right

  if player.dx<0 then
    if collide_map(player, "left", 1) or player.x <= minx then 
      player.dx=0
    end
    if collide_map(player, "left", 7) and FOUND_SNACK then
      FOUND_CAT=true
      FOUND_CAT_TIME=time()
      player.dx=0
    end
  elseif player.dx>0 then
    if collide_map(player, "right", 1) or player.x >= maxx then 
      player.dx=0
    end
    if collide_map(player, "right", 7) and FOUND_SNACK then
      FOUND_CAT=true
      FOUND_CAT_TIME=time()
      player.dx=0
    end
  end

  -- todo: cleanup this messy fn
  local d = { "up", "down", "left", "right" }
  for i=1,4 do
    if collide_map(player, d[i], 4) and not FOUND_SNACK then
      FOUND_SNACK=true
      sfx(1)
    end
  end

  -- check idle
  if abs(player.dx)<0.005 and player.dy==0 then
    player.dx=0
    player.running=false
    player.jumping=false
    player.direction=0
  end

  if player.x < maxy then
    player.x+=player.dx
  end
  player.y+=player.dy

  if player.y>maxy then reset_player_location() end
end

function reset_player_location()
  player.x=startx
  player.y=starty
  player.dx=0
  player.dy=0
end

function collide_map(obj,dir,flag)
  -- obj needs x y w h
  local x=obj.x
  local y=obj.y
  local w=obj.w
  local h=obj.h
  
  local x1=0
  local y1=0
  local x2=0
  local y2=0

  if dir=="left" then
    x1=x-1
    y1=y
    x2=x
    y2=y+h-1
  elseif dir=="right" then
    x1=x+w-1
    y1=y
    x2=x+w
    y2=y+h-1
  elseif dir=="up" then
    x1=x+1
    y1=y-1
    x2=x+w-1
    y2=y
  elseif dir=="down" then
    x1=x+3
    y1=y+h
    x2=x+w-4
    y2=y+h
  end
  -- test
  x1r=x1
  y1r=y1
  x2r=x2
  y2r=y2
  -- test
  x1/=8
  y1/=8
  x2/=8
  y2/=8
  x1+=(LEVEL*32)
  x2+=(LEVEL*32)
  if fget(mget(x1,y1),flag)
  or fget(mget(x1,y2),flag)
  or fget(mget(x2,y1),flag)
  or fget(mget(x2,y2),flag) then
    return true
  else
    return false
  end
end
__gfx__
0000000000006060eeee5e5e0444444056565555bbbbbbbb54444455effffff700000077044444400444444000005050111111111111111111444411eeeeeeee
00000000500065656eee64744ffffff49ffffff9b33bb3bb444444552effff7f033330004ffffff40ffffff0f4f05540111111111111111111444411eeeeeeee
0000000005005797e6ee47b74f3fff349f3fff39353333b34444454422eeeeff333367074f0fff040f0fff0040405464111115111111151144444411eeeeeeee
00000000600077777eee65744effffe4099fff90355553334444444422eeeeff363666004ffffff40ffffff0f00044f7111155111511551114444411eeeeeeee
00000000556577706745454e4f2222440fdddd00445334554445444422eeeeff33333a3a0499994000788700f5544ff0111151111511511111444441eeeeeeee
0000000007577770e457546e04422f40000ddf00454454454455444422eeeeff3333333340f99f0400f77f004554ff70111151111551511111444441eeeeeeee
00000000077777704476467e044cc440000440004445445444444444221111ef55355333040cc0400008800047455570111551111155515111444441eeeeeeee
00000000707070076e6e6ee6004c4c00000f0f0055544444444444452111111e55055055000cc0000005500070707070111555111115555111444411eeeeeeee
cccc7c7c000060600000505004444440565655554444444411111111d6666667bbbbb111111bbbbb1115551111155511151555111111551111444411eeebbbbb
5ccc777750006565600064744ffffff49ffffff945544544111111115d666676b33bb311113bb3bb1115551111155515551555111111511111444411ee3bb3bb
c5cc57b705005797060047b74f3fff349f3fff39455555441111111155dddd66353333b1153333b31155551111555555155555511115551114444411e53333b3
5ccc777760007777700065744effffe4099fff90455555541111111155dddd663555533135555333111555111115555111555511111555111144441435555333
5777777c55657770674545404422224400dddd00445554541111111155dddd664453345544533455115555511115555111555511111555111144441444533455
c777777c075777700457546004f22f4000fddf00454454441191117155dddd664544544545445445115555111115551111155511111155111144444145445445
c777777c0777777044764670044cc440000440004444445439a917a7551111d64445445444454454111555111115551115155511111555111144441144454454
7c7c7c7c7070707060606060004cc400000ff0004444444413911b7b5111111d5554444455544444111555111115551115555511111555111144441155544444
04444440044444400000707004444440565655555444445511117111bb33444411111111111111111115551111111111111555114144441111444411bbbbbeee
4ffffff44ffffff4500077774ffffff49ffffff94444445511567111bb34445511711111111111115115551111111111111555114144441111444411b33bb3ee
4f3fff344f3fff34050057b74f3fff349f3fff394444454411566711b3bbb44516111117111111111555551111111111111555114144441111444411353333be
4effffe44effffe4500077774effffe4099fff904444444415566711bbb3b454111111111111111111555511111111111115551141444411114444113555533e
442f22f44f2222f457777770442222f400ddddf04445444415d66671bb3344441111111111111111115555111111111111155511444444411144441144533455
04422440044224400777777004f2244000fdd0004455444455d66671bbb444441111111111111111111555111111111111155511114444441144441145445445
044cc440044cc44007777770044cc440000440004444444455dd6667bbb454541111711111111111111555111111111111155511114444111144441144454454
00c4c40000c44c007070700700c4c40000f0f00044444445555ddd663b3344441111111111111111111555111111111111155511114444111144441155544444
11117171044444400ee00ee004444440565655551171111111134444bb3344441111111111111111bb334111bb3344441113bbbb1144441111bbbb11eebbbbee
5111777748888884e88ee88e4ffffff49ffffff917a7111111344455bb3444551111111111711111bb344411bb344455113bb455114444111b3bb3b1eb3bb3be
151157b748388834e878888e43fff3f493fff3f91171111113bbb445b3bbb4451111111111611111b3bbb441b3bbb44513bbb44511444411153333b1e53333be
511177774e8888e4e887888e4effffe4099fff9011311111bbb3b454bbb3b4541111111111111111bbb3b454bbb3b454bbb3b454114444143555533335555333
5777777148222284e888888e4422224400dddd00113b1111bb334444bb3344441111111111111111bb334444bb334444bb334444144444444453345544533455
1777777104422440ee8888ee04f22f4000fddf001b3111e1bbb444441bb444441111111111111111bbb44444bbb44441bbb44444114444444544544545445445
17777771044cc4400ee88ee0044cc4400004400011311eaebbb4545411b454541171111111111171bbb45454bbb45411bbb45454114444114445445444454454
7171717100c44c0000eeee00004cc400000ff00011311beb3b3344441113444411111111111111113b3344443b3341113b334444114444115554444455544444
1144811111111111ee448eee0444444056565555cccbbbbb11111111111117777777111111111111eeeeeeeeeeeee999999999aeeeeeeeeecc3cccccccccc3cc
14889a1111111111e4889aee4ffffff49ffffff9cc3bb3bb11111111117777777777777111111111eeeeeeeeee9999a99999999aaeeeeeeecc7cccccccccc3cc
4899a011111111114899a0ee43fff3f493fff3f9c53333b311111111177777777777777711111111eeeeeeeea99a9a9a999999999aeeeeeec7a7ccccccccc33c
48890991111111114889099e4effffe4099fff903555533311111117777777777777777777111111eeeeeeea999999a9999999a999aeeeeecb73cccccccccc33
8339a0a9111111118339a0a9442222f40fdddd004453345511111177777777777776767777711111eeeeeea999999a999a999999999aeeeeccb3cccccccccccb
19939a9811111111e9939a9804f22440000ddf004544544511111777777777777777777777771111eeeeea9a999a999999999a999999aeeecc33ccccccccccc3
1111999911111111eeee9999044cc440000440004445445411111777777777777777777777771111eeeea99999999999999999999a99aeeecc3ccbcccccccc73
1111911911111111eeee9ee9004c4c0000f0f0005554444411117777767777777767777777777111eeeea9a99a9a99999a99999999999aeecc33bccccccbc7a7
ee7eeeeeeeeeeeeecccccccc0444444056565555bbbbbccc11177777777777777777777777777711eeea999999a99aa999a99a999999a9aecccc3cccccccb37c
e7a7eeeeeeeeeeeecccccccc4ffffff49ffffff9b33bb3cc11177677777777777777777777777711eeea99999a9a999999999999999999aecccc3c7cccccc3cc
ee7eeeeeeeeeeeeecccccccc43fff3f493fff3f9353333bc11177777777777777777777777777711eeea999a99a999999999999999a999aecccc37a7ccccc3bc
ee3eeeeeeeeeeeeecccccccc4effffe4099fff903555533c11777777677777776777777777777771eea99aa9a9999a99999999999999999acccccb7ccccc33cb
ee3beeeeeeeeeeeecccccccc4f22224400ddddf04453345511777767777777777777777777777771eeaa999a99a9999a9999a99a9999a99acccccc3cccb33ccc
eb3eeeceeedeee7ecccccccc04422f4000fdd0004544544511777677677777777767777777777771eea999999a9a99999999a999999a999acccccc33bc3bcccc
ee3eecac3dade7a7cccccccc044cc440000440004445445411767767777777776777777777777771eea99a9999a99a99a99a9a999999999acccccccbcc3ccccc
ee3eebcbe3deeb7bcccccccc00c4c400000f0f005554444411776777677777777777777777767771eea99999999999999999a9999a9a9a9acccccc33333ccccc
eeee7eeebaaaaaa7ccbbbbcc5555555556565555cccc7ccc11777767777777777777777776777771eea9a99999999999999999999999999acc3cccccccccc3cc
ee567eee3baaaa7acb3bb3bc988888899ffffff9cc567ccc11776777677777777777777777677771eea999a999a99999999999a99a9a999acc7cccccccccc3cc
ee5667ee33bbbbaac53333bc983888399f3fff39cc5667cc11777777777777777777777777777771eea999999999999a999a9a9a999a9a9ac7a7ccccccccc33c
e55667ee33bbbbaa3555533309988890099fff90c55667cc11177767777777777777777777777711eeea9a99a9a99999999999a9999a99aecb73cccccccccc33
e5d6667e33bbbbaa4453345508dddd800fddddf0c5d6667c11177777777777777777777776777711eeea9999999999a9999999999a9999aeccb3cccccccccccb
55d6667e33bbbbaa45445445000dd000000dd00055d6667c11177777777777777777777777777711eeea999a999999999a999999999a99aecc33ccccccccccc3
55dd6667335555ba44454454000440000004400055dd666711117777767777777777777677777111eeeea9999a999999999999999a99aeeecc3ccbcccccccc73
555ddd663555555b555444440080080000f00f00555ddd6611111777677777777777777777771111eeeeea99999999999999a9a9999aeeeecc33bccccccbc7a7
eeeeeeeeeeeeeeeecc448ccccc7ccccc56565555cccccccc11111777777777777777767777771111eeeeea9a99999a9999999999999aeeeecccc3cccccccb37c
eeeeeeeeeeeeeeeec4889accc7a7cccc9ffffff9cccccccc11111177777777777777777777711111eeeeeea9999999999999999999aeeeeecccc3cdcccccc3cc
eeeeeeaeeeeeeeee4899a0cccc7ccccc9f3fff39cccccccc11111117777777777777777777111111eeeeeeeaa9999999a999a99aaaeeeeeecccc3dadccccc3bc
eeeeeeeeeeeeeeee4889099ccc3ccccc099fff90cccccccc11111111177777777777777711111111eeeeeeeeea999999999a9a9aeeeeeeeecccccbdccccc33cb
eeeeeeeeeeeaeeee8339a0a9cc3bcccc00dfddf0cccccccc11111111117777777777777111111111eeeeeeeeee9999999999aaaeeeeeeeeecccccc3cccb33ccc
eaeeeeeeeeaeaeeec9939a98cb3ccc8c000dd000cceccc7c11111111111117777777111111111111eeeeeeeeeeeee999999aeeeeeeeeeeeecccccc33bc3bcccc
eeeeeeeeeeeaeeeecccc9999cc3cc8a8000440003eaec7a711111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccbcc3ccccc
eeeeeeeeeeeeeeeecccc9cc9cc3ccb8b00f0f000c3eccb7b11111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccc33333ccccc
9181b2b2b2b27171b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f00707f0f0f0f00707707070700707f0f0f0f0f0f0f0f0f0f070f0f0f0707070
25252525252525252525252526162525252525252525252525e7f725161625250000000000000000000000000000000000000000000000000000000000000000
7171b2b2b2b27171b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f007f0f007070707070707f0f00707f005f0f0f0f0f0f0f0f070f0f0f0f07070
25252525252525252525572616252525252556562525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f007f00707070707f0070707070707f0f150f2f0f0f0f0f0f070f3f0f0f0f070
2525252525263725262526162525252525e516162525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2915081b2b2b2b2b2b2b2b2b2717171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f00717070707f0f0f0f0f007070707f0707070f0f0f0f0f0f07070f0f0f02470
252525252616545516261625252525252525f6252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2717171b2b2b2b2b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f007070707f005f0f0f015f0f0f0f0f3f0f0f0f0f0f0f0f0f07070f30606f370
2525252616e71616f4162525252525252525f7252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2915081b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f00707f0f1505050505050f2f0f070f0f0f0f0f0f0f0f0f070707070707070
252525162525e625f5252525252525252525e4252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2717171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f00707f07070707070707070f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
3725252525252525e625252525252525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b261b2b2b253b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f007f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
54505050505055252525252525252525255455252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b29150505050505081b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f205f00707f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
16161616161616252525252525252525251616252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b27171717171717171e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b270f3f0f007070707070707070707f0f0f1505050505050f2f0f0f0f0f0f0f0f0
25252525252525252525575450552525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b271e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b27070f3f01707070707070707070707f07070707070707070f0f0f0f0f0f0f0f0
25252525252525252525261616162625252525252525262525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b271e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f07070f3f0f0f0f0f0f0f0f007070707f0f0f0f0f0f0f0f0070707f0f0f0f0f0
252525252525252525251616e6161625252525252554165525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b271e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f07070f0f0f0f0f0f0f0f006f007070707f0f00707070707f0f007f0f0f0f0
25252525252525252525f425e7e4e625252525252516e71625252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b271b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f015f0f0f0f0f070f0f0f00707070707f0f0f0f006f00707f0f0f0
25252525252525252525f525f7e5f425252525252525252525252625252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2615361b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f1f2f0f0f0f0f0f0f0f0f0f017f0f0f0f0f0f070f0f00707f0f0
252525252525252525252525e625f525252525252525252525251626252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b29150505050505081b2b2b2b2b2b2b2b2b2b2b2f0f006f0f0f07070f3f0f0f0f0f0f007070707f0f0f0070707f0f0f0f007f0f0
2525252525252525252525252525252525252525252525252525e516252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2e37171717171717171b2b2b2b2b2b2b2b2b2b2b2f0f070f0f0f0f07070f3f0f0f0f007f0f01707f0f00707f007f0f0f0f00717f0
25252525252525252525252525252525252525252525252525255737252525570000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b271b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f07070f3f0f0f007f0f0f007070707f0f00707f0f0f00707f0
25252525252525252525252525252525252525252625252554505050505050550000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b261b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f006f0f0f0f07070f3f0f007f0f0f0f0f0f0f0f0f00707f0f0f00707f0
25252525252525252525252525252525252526251625252516161616161616160000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b29150505081b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f070f0f0f0f0f07070f30707f0f0f0f0f0f0f0f0f00707f0f00707f0f0
25252525252525252525252525252525262516f52525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
6262626253626262627171717171b2b2b2b2b2b291505050505081b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0707007f0f0f1f2f0f0f3f0f0f01707070707f0f0f0
2525252525252525252525252537252516f525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
60516060606051606071b2b2b2b2b2915050508171717171717171b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f00717f0f07070f0f070f0f0f0f0f0f0f0f0f0f0f0
25252525252525252525252554505525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
71717171717171717171b2b2b2b2b2717171717171b2b2b2b2b2e2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f00707f006f0f0f0f0f3f0f0f1f2f0f0f0f0f0f0f0f0
25252525252525252525252516161625252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2d2d091505081f0f0f0f0f0f0f0f0f0f00707f0f070f00707f070f0f07070f0f0f0f005f0f0f0
25252525252525252525252525252525255656565625252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2e1c171717171f0f0f0f0f0f0f0f0f0f00707f0f0f007070717f0f0f0f0f0f0f0f0f150505050
57252525252525252526252525252525251616161625252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b29181e2b2e0b2f150f2f0f0f0f0f0f0f0170707070707f00707070707070707f0f37070707070
50552525252525252516262525252525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b261b2b2b2b261b2b2b2b2b2b2b2b2b27171e0b2e2b2707070f0f0f015f0f0f0f0f0f0f0f0f3f0f0f0f0f0f0f0f0070770f0f0f0f0f0
606026252525252525e7162525252525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b29150505050505050505081b2b253b2b2e0a2d2c0e2b2f0f0f0f0f0f0f1f2f0f0f005f0f0f070f0f0f0f315f3f0f1f207f0f0f0f0f0f0
16606026252525252525252525252525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b27171717171717171717171b2915081b2d2c2d3c2e2b2f0f0f0f0f0f07070f0f0f1505050f2f0f0f0f1515052f25251070707f0f0f0f0
16165160505055252525252525255455252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b261b2b2537171717171717171717171b2717171b2e2c2e0c2e2b2f0f0f0f005f07070f0f07070707070f0f0f070707070707070f0f007070707f0
16161651606051262557252525251616252525573725252525372525255725250000000000000000000000000000000000000000000000000000000000000000
915050505050505050507171717171717171717171b2b2b2b2b2e2b1e2c2e2b2f150505050f27070f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
16161616161616605450505055252525252554505050505050505050505050550000000000000000000000000000000000000000000000000000000000000000
717171717171717171717171717171717171717171b2b2b2b2b2e2c2e2c2d2b27070707070707070060606060606060606060606060606060606060606060606
16161616161616161616161616565656565616161616161616161616161616160000000000000000000000000000000000000000000000000000000000000000
__gff__
0080800000010203000000000000000080808000000200030303000000000003000080000002060200000000000000038000000000000302000002020300030310001000000300000000000000000000000000000003000000000000000000000603030000060000000000000000000000001000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
382b382b38282b2b2b2b464748492b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
2b282b382b382b38392b565758592b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b382b666768692b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
2b382b38282b392b2b39767778792b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
162b302b2b2b352b2b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
05050505050505182b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525275735252105252527375525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
06152506251525252b2b2b2b2b2b2b2b2b2b382b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252450505050505050505050505055552525252525252525252520000000000000000000000000000000000000000000000000000000000000000
15060625152525062b2b2b2b2b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525262616161616161616161616161616162525252525252525252520000000000000000000000000000000000000000000000000000000000000000
171717171717171719182b2b2b19050505182b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525261614e4f5252525252527e6152526161525252525252525252520000000000000000000000000000000000000000000000000000000000000000
392e383d171717171717382b3e25152525062b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f525252525252616e5e5f525252525252526152525252526252525252525252520000000000000000000000000000000000000000000000000000000000000000
400e0d2e1717172b2b382b381717171717172b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f525252525252614f5252525252525252526152525252526152525252525252520000000000000000000000000000000000000000000000000000000000000000
382d1b0e1717172b2b2b2b2b2b1717171717382b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f525252525252615f5272525252525252526152525252735252625252525252520000000000000000000000000000000000000000000000000000000000000000
1d3d2c1e1d17172b2b1918382b2b2b2b2b382b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f52525252525261450505055552525252736152525252450555615252525252520000000000000000000000000000000000000000000000000000000000000000
0505182e1b2e0c282b17172b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f707070707071707070700f0f0f0f52525252525261616161616152525245056162525252616161525252525252520000000000000000000000000000000000000000000000000000000000000000
2c2e1c2e2a2e2c352b2b2b393e2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f700f7070700f71700f70700f0f0f52525252525252525252615f52525261616161525252526e6f525252525252520000000000000000000000000000000000000000000000000000000000000000
1c1e2c2e190505182b2b382b17382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f70707170714a4b4c4d700f700f0f0f5252525252525252525261525252626e6f5252627552527e7f525252525252520000000000000000000000000000000000000000000000000000000000000000
1b0e2c2e061506062b2b2b2b162b2b2b2b352b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7070700f705a5b5c5d7071700f0f0f5252525252525252525261525252617e7f5252616252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
26262626060606152b2b2b190505050505051826261905182b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f70700f706a6b6c6d0f70700f0f0f52525252525252525252616252525252525252526152625252525252525252520000000000000000000000000000000000000000000000000000000000000000
152506251517171719182b171717171717171717171525172b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7070707070707a7b7c7d71700f0f0f0f52525252525252525252610662525252525252525252616252525252525252520000000000000000000000000000000000000000000000000000000000000000
062515252517392b17172b2b282b2b2b2b2b2b28172506172b352b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f700f7070717071700f7070700f0f0f0f525252525252525252525261156252525252525252525e6152525252525252520000000000000000000000000000000000000000000000000000000000000000
1717171717172b2b2b282b2b2b38392b2b2b2b2b171717172b19182b382b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7070700f0f0f0f70707070710f0f0f0f0f52525252525252525252525261066275735252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
171717171717282b2b2b2b2b2b2b2b2b2b2b392b2b2b2b2b3817172b282b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f70700f0f0f0f0f0f0f020f0f0f0f0f0f52525252525252525252525252611545055552525252525252525245055552520000000000000000000000000000000000000000000000000000000000000000
2b2b382b39172b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b162b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7070710f0f0f0f0f1f052f0f0f0f0f0f52525252525252525252525252526161616152526252525252525261616152520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b1905180f0f0f0f0f0f0f0f0f0f0f7070707070700f700f0f0f0f0f0f0f0f0f0f0f0f0f52525252525252525252525252525252525252526152526252525252525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b2b2b2b162b2b2b2b2b3c05182b2b2b2b2b2b3e1717170f0f0f0f0f0f0f0f0f0f0f700f0f0f0f0f70700f0f0f0f0f0f0f0f0f0f510f0f52525252525252525252525252525252525252525252526152525252525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b3c050505050505050517171719182b2b2b2b172b2b2b0f0f0f0f0f0f0f0f0f0f0f70700f707070700f510f0f0f0f0f0f0f0f1f2f0f0f52525252525252525252525252525252525252525252525252527352525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b271525252525252515172b2b17172b2b2b2b2b16352b0f0f0f0f0f0f0f0f0f0f0f0f7071700f0f0f1f05050505052f0f0f0f07070f0f52525252525252525252525252525252525252525252525252450555525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b35272525252515252525172b2b2b2b2b2b1905050505180f0f0f0f0f0f0f0f0f0f0f0f0f7070700f0f07070707070707500f0f0f0f0f0f52525252525252525252525252525252525252525245050555616161525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b190505050505060617171717171717172b2b2b2b2b2b1717171717170f0f0f7070700f0f0f0f0f0f0f0f0f700f0f0f0f0f0f0f0f0f3f0f0f0f0f0f3f52525252525252525252525252734505555252525261616161614f52525252520000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b17171717171717171717172b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f70700f707070711f05052f0f70700f0f0f0f0f0f0f0f0f070f0f0f3f3f07525252525252525252525252526261616152525252525252526e6f52656552520000000000000000000000000000000000000000000000000000000000000000
__sfx__
91030000205361853612536105360e5360d5360c5360d5360f536125361653621536225360c5060950607506075060a5060d5060a506055060050600506005060050600506005060050600506005060050600506
c102000038550315502755017550145501155011550175501f550285503b5503e55024500295002c5003350037500335002a500245001f5001e500205002250024500265002d5003650000500005000050000500
3102000000502005021a5521a5521b5521b5521c5521d5521e5521e5521f552005022055220552005022255200502235520050223552005020050225552005020050200502265520050200502275520050200502
310400001c55023550185501c550225501c5502355000000185001c50022500265002a5002c5002d5002d5001c500235000000000000000000000000000000001c50023500000000000000000000000000000000
