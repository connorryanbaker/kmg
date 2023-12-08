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
  CAT_NAME={[0]="Horatio",[1]="Joe Buck",[2]="Georgia"}
  minx=0
  miny=0
  maxx=256
  maxy=512
  min_cam_y=0
  max_cam_y=388
  max_cam_x=maxx/2
  startx=3
  starty=-3
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
    spr(57,0,96)
  end
  if not FOUND_SNACK then
    -- todo: sprite over cat coordinate per level
    spr(22,16,48)
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
      local x
      local y = player.y - 10 * i
      if i%2==0 then x = player.x-10 else x = player.x+10 end
      spr(50, x, y)
    end
    local name = CAT_NAME[LEVEL]
    print("You found "..name.."!", player.x+20, player.y-20, 9)
    if LEVEL<2 then print("Let's go find "..CAT_NAME[LEVEL+1].."!", player.x+20, player.y-10, 9) end
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
  -- cam_y=mid(miny, player.y-64+player.w/2, maxy)
  if cam_y > maxy then cam_y=max_y end
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
  player.dy+=gravity
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
    if collide_map(player, d[i], 4) then 
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

  -- local nx = player.x+player.dx
  -- if nx >=0 and player.w+nx<maxx then player.x=nx end
  player.x+=player.dx
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
0000000000006060000050500444444055555555bbbbbbbb54444455effffff700000077044444400444444000005050111111111111111111444411eeeeeeee
0000000050006565600064744ffffff49ffffff9b33bb3bb444444552effff7f033330004ffffff40ffffff0f4f05540111111111111111111444411eeeeeeee
0000000005005797060047b74f3fff349f3fff39353333b34444454422eeeeff333367074f0fff040f0fff0040405464111115111111151144444411eeeeeeee
0000000060007777700065744effffe4099fff90355553334444444422eeeeff363666004ffffff40ffffff0f00044f7111155111511551114444411eeeeeeee
0000000055657770674545404f2222440fdddd00445334554445444422eeeeff33333a3a0499994000788700f5544ff0111151111511511111444441eeeeeeee
00000000075777700457546004422f40000ddf00454454454455444422eeeeff3333333340f99f0400f77f004554ff70111151111551511111444441eeeeeeee
000000000777777044764670044cc440000440004445445444444444221111ef55355333040cc0400008800047455570111551111155515111444441eeeeeeee
000000007070700760606006004c4c00000f0f0055544444444444452111111e55055055000cc0000005500070707070111555111115555111444411eeeeeeee
00007070000060600000505004444440555555554444444411111111d6666667bbbbb111111bbbbb1115551111155511151555111111551111444411eeebbbbb
5000777750006565600064744ffffff49ffffff945544544111111115d666676b33bb311113bb3bb1115551111155515551555111111511111444411ee3bb3bb
050057b705005797060047b74f3fff349f3fff39455555441111111155dddd66353333b1153333b31155551111555555155555511115551114444411e53333b3
5000777760007777700065744effffe4099fff90455555541111111155dddd663555533135555333111555111115555111555511111555111144441435555333
5777777055657770674545404422224400dddd00445554541111111155dddd664453345544533455115555511115555111555511111555111144441444533455
07777770075777700457546004f22f4000fddf00454454441191117155dddd664544544545445445115555111115551111155511111155111144444145445445
077777700777777044764670044cc440000440004444445439a917a7551111d64445445444454454111555111115551115155511111555111144441144454454
707070707070707060606060004cc400000ff0004444444413911b7b5111111d5554444455544444111555111115551115555511111555111144441155544444
04444440044444400000707004444440555555555444445511117111bb33444411111111111111111115551111111111111555114144441111444411bbbbbeee
4ffffff44ffffff4500077774ffffff49ffffff94444445511567111bb34445511711111111111115115551111111111111555114144441111444411b33bb3ee
4f3fff344f3fff34050057b74f3fff349f3fff394444454411566711b3bbb44516111117111111111555551111111111111555114144441111444411353333be
4effffe44effffe4500077774effffe4099fff904444444415566711bbb3b454111111111111111111555511111111111115551141444411114444113555533e
442f22f44f2222f457777770442222f400ddddf04445444415d66671bb3344441111111111111111115555111111111111155511444444411144441144533455
04422440044224400777777004f2244000fdd0004455444455d66671bbb444441111111111111111111555111111111111155511114444441144441145445445
044cc440044cc44007777770044cc440000440004444444455dd6667bbb454541111711111111111111555111111111111155511114444111144441144454454
00c4c40000c44c007070700700c4c40000f0f00044444445555ddd663b3344441111111111111111111555111111111111155511114444111144441155544444
1111717104444440eee0eee004444440555555551171111111134444bb3344441111111111111111bb334111bb3344441113bbbb1144441111bbbb11eebbbbee
5111777748888884e88088e04ffffff49ffffff917a7111111344455bb3444551111111111711111bb344411bb344455113bb455114444111b3bb3b1eb3bb3be
151157b748388834e88888e043fff3f493fff3f91171111113bbb445b3bbb4451111111111611111b3bbb441b3bbb44513bbb44511444411153333b1e53333be
511177774e8888e4e88888e04effffe4099fff9011311111bbb3b454bbb3b4541111111111111111bbb3b454bbb3b454bbb3b454114444143555533335555333
5777777148222284e88888e04422224400dddd00113b1111bb334444bb3344441111111111111111bb334444bb334444bb334444144444444453345544533455
17777771044224400e888ee004f22f4000fddf001b3111e1bbb444441bb444441111111111111111bbb44444bbb44441bbb44444114444444544544545445445
17777771044cc44000e8ee00044cc4400004400011311eaebbb4545411b454541171111111111171bbb45454bbb45411bbb45454114444114445445444454454
7171717100c44c00000e0000004cc400000ff00011311beb3b3344441113444411111111111111113b3344443b3341113b334444114444115554444455544444
11448111111111110000000004444440555555550000000011111111111117777777111111111111ee7eeeeeeeeeeeeeeeee7eee000000000000000000000000
14889a1111111111000000004ffffff49ffffff90000000011111111117777777777777111111111e7a7eeeeeeeeeeeeee567eee000000000000000000000000
4899a011111111110000000043fff3f493fff3f90000000011111111177777777777777711111111ee7eeeeeeeeeeeeeee5667ee000000000000000000000000
4889099111111111000000004effffe4099fff900000000011111117777777777777777777111111ee3eeeeeeeeeeeeee55667ee000000000000000000000000
8339a0a91111111100000000442222f40fdddd000000000011111177777777777776767777711111ee3beeeeeeeeeeeee5d6667e000000000000000000000000
19939a98111111110000000004f22440000ddf000000000011111777777777777777777777771111eb3eeeceeedeee7e55d6667e000000000000000000000000
111199991111111100000000044cc440000440000000000011111777777777777777777777771111ee3eecac3dade7a755dd6667000000000000000000000000
111191191111111100000000004c4c0000f0f0000000000011117777767777777767777777777111ee3eebcbe3deeb7b555ddd66000000000000000000000000
00000000000000000000000004444440555555550000000011177777777777777777777777777711000000000000000000000000000000000000000000000000
0000000000000000000000004ffffff49ffffff90000000011177677777777777777777777777711000000000000000000000000000000000000000000000000
00000000000000000000000043fff3f493fff3f90000000011177777777777777777777777777711000000000000000000000000000000000000000000000000
0000000000000000000000004effffe4099fff900000000011777777677777776777777777777771000000000000000000000000000000000000000000000000
0000000000000000000000004f22224400ddddf00000000011777767777777777777777777777771000000000000000000000000000000000000000000000000
00000000000000000000000004422f4000fdd0000000000011777677677777777767777777777771000000000000000000000000000000000000000000000000
000000000000000000000000044cc440000440000000000011767767777777776777777777777771000000000000000000000000000000000000000000000000
00000000000000000000000000c4c400000f0f000000000011776777677777777777777777767771000000000000000000000000000000000000000000000000
00000000000000000000000055555555555555550000000011777767777777777777777776777771000000000000000000000000000000000000000000000000
000000000000000000000000988888899ffffff90000000011776777677777777777777777677771000000000000000000000000000000000000000000000000
000000000000000000000000983888399f3fff390000000011777777777777777777777777777771000000000000000000000000000000000000000000000000
00000000000000000000000009988890099fff900000000011177767777777777777777777777711000000000000000000000000000000000000000000000000
00000000000000000000000008dddd800fddddf00000000011177777777777777777777776777711000000000000000000000000000000000000000000000000
000000000000000000000000000dd000000dd0000000000011177777777777777777777777777711000000000000000000000000000000000000000000000000
00000000000000000000000000044000000440000000000011117777767777777777777677777111000000000000000000000000000000000000000000000000
0000000000000000000000000080080000f00f000000000011111777677777777777777777771111000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555550000000011111777777777777777767777771111000000000000000000000000000000000000000000000000
000000000000000000000000000000009ffffff90000000011111177777777777777777777711111000000000000000000000000000000000000000000000000
000000000000000000000000000000009f3fff390000000011111117777777777777777777111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000099fff900000000011111111177777777777777711111111000000000000000000000000000000000000000000000000
0000000000000000000000000000000000dfddf00000000011111111117777777777777111111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000dd0000000000011111111111117777777111111111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000440000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
0000000000000000000000000000000000f0f0000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
9181b2b2b2b27171b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7171b2b2b2b27171b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2915081b2b2b2b2b2b2b2b2b2717171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2717171b2b2b2b2b2b2b2b2b27171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0a4f0f0f0b4f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2915081b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f1505050505050f2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2717171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f07070707070707070f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b261b2b2b253b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b29150505050505081b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f2b4f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b27171717171717171e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b270f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1505050505050f2f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b271e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b27070f3f0f0f0f0f0f0f0f0f0f0f0f0f07070707070707070f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b271e3b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f07070f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b271b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f07070f0f0f0f0f0f0f0f062f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2615361b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0a4f0f0f0f0f070f0f0f0f0f0f0f0f0f0f0f0f062f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2915050505081b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f1f2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f070f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b29181717171717171b2b2b2b2b2b2b2b2b2b2b2f0f0c4f0f0f07070f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2e3717171b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f070f0f0f0f07070f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b271b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f07070f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b261b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0c4f0f0f0f07070f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b29150505081b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2f0f0f0f070f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6262626253626262627171717171b2b2b2b2b2b291505050505081b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1f2f0f0f3f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60516060606051606071b2b2b2b2b2915050508171717171717171b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f07070f0f070f0f1f2f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71717171717171717171b2b2b2b2b2717171717171b2b2b2b2b2b2b2b2b2b2b2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f07070f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b291505081f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f3f0f0a4f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b271717171f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f070f0f150505050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2e3b2b2b2b2b2f150f2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f07070707070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b2b261b2b2b2b261b2b2b2b2b2b2b2b2b271b2b2b2b2b2707070f0f0f0a4f0f0f0f0f0f0f0f0f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b29150505050505050505081b2b253b2b2b2b2b2b2b2b2f0f0f0f0f0f0f1f2f0f0f0a4f0f0f070f0f0f0f3b4f3f0f1f2f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b2b2b2b2b27171717171717171717171b2915081b2b2b2b2b2b2b2f0f0f0f0f0f07070f0f0f1505050f2f0f0f0f1515052f25251f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b2b2b2b2b261b2b2537171717171717171717171b2717171b2b2b2b2b2b2b2f0f0f0f0b4f07070f0f07070707070f0f0f070707070707070f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
915050505050505050507171717171717171717171b2b2b2b2b2b2b2b2b2b2b2f150505050f27070f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
717171717171717171717171717171717171717171b2b2b2b2b2b2b2b2b2b2b27070707070707070c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4
__gff__
0080800000010203000000000000000080808000000200030303000000000003000080000002060200000000000000038000000000000302000002020300030310000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
382b382b38282b2b2b2b464748492b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b282b382b382b38392b565758592b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b382b666768692b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b382b38282b392b2b39767778792b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
162b302b2b2b352b2b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505050505182b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06152506251525252b2b2b2b2b2b2b2b2b2b382b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15060625152525062b2b2b2b2b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171717171717171719182b2b2b19050505182b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
392e383d171717171717382b3e25152525062b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400e0d2e1717172b2b382b381717171717172b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
382d1b0e1717172b2b2b2b2b2b17171717172b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d3d2c1e1d17172b2b1918382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505182e1b2e0c282b17172b382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2e1c2e2a2e2c352b2b2b393e2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1e2c2e190505182b2b382b17382b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b0e2c2e061506062b2b2b2b162b2b2b2b352b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26262626060606152b2b2b190505050505051826261905182b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
152506251517171719182b171717171717171717171525172b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0625152525172b1717172b2b2b2b2b2b2b2b2b2b172506172b352b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1717171717172b2b2b2b2b2b2b2b2b2b2b2b2b2b171717172b19182b382b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171717171717182b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b17172b282b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b17172b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b162b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b1905180f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b26262b2b2b2b2b162b2b2b2b2b3c05182b2b2b2b2b2b2b1717170f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b17172b2b3c05050505050505051717172b2b2b2b2b172b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b2b271525252525252515172b2b2b2b2b2b2b2b2b16352b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b2b2b2b2b35272525252515252525172b2b2b2b2b190505050505180f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b190505050505060617171717171717172b2b2b2b2b171717171717170f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b2b2b17171717171717171717172b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001d00000000000000000000000000000000000000000000000000405007050090500c0500c0500905007050070500a0500d0500a050050500000000000000000000000000000000000000000000000000000000
