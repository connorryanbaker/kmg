pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
  player={
    x=3,
    y=104,
    s=19,
    ws={[0]=19,[1]=35,[2]=19,[3]=3},
    f=0,
    dx=0,
    is={[0]=19,[1]=51}
  }
  tick=0
  fs=false
end

function _update()
  tick=(tick+1)%30
  -- todo - dx / dy etc
  local mvmt=true
  if btn(⬅️) then
    fs=true
    player.dx=-1
  elseif btn(➡️) then
    fs=false
    player.dx=1
  else
  		mvmt=false
    player.dx=0 
  end

  player.x += player.dx
  
  if player.dx != 0 and tick%5==0 then
    player.f = (player.f+1)%4
    player.s = player.ws[player.f]
  elseif tick%20==0 then
    player.f = (player.f+1)%2
    player.s = player.is[player.f]
  end
end

function _draw()
  cls()
  map(0,0)
  spr(player.s,player.x,player.y,1,1,fs)
end
__gfx__
0000707000006060000050500444444055555555bbbbbbbb54444455effffff70000007704444440044444400000505000000000000000000000000000000000
5000777750006565600064744ffffff49ffffff9b33bb3bb444444552effff7f033330004ffffff40ffffff0f4f0554000000000000000000000000000000000
050057b705005797060047b74f3fff349f3fff39353333b34444454422eeeeff333367074f0fff040f0fff004040546400000000000000000000000000000000
5000777760007777700065744effffe4099fff90355553334444444422eeeeff363666004ffffff40ffffff0f00044f700000000000000000000000000000000
5777777055657770674545404f2222440fdddd00445334554445444422eeeeff33333a3a0499994000788700f5544ff000000000000000000000000000000000
07777770075777700457546004422f40000ddf00454454454455444422eeeeff3333333340f99f0400f77f004554ff7000000000000000000000000000000000
077777700777777044764670044cc440000440004445445444444444221111ef55355333040cc040000880004745557000000000000000000000000000000000
707070077070700760606006004c4c00000f0f0055544444444444452111111e55055055000cc000000550007070707000000000000000000000000000000000
00007070000060600000505004444440555555554444444400000000d66666670000000000000000000000000000000000000000000000000000000000000000
5000777750006565600064744ffffff49ffffff945544544000000005d6666760000000000000000000000000000000000000000000000000000000000000000
050057b705005797060047b74f3fff349f3fff39455555440000000055dddd660000000000000000000000000000000000000000000000000000000000000000
5000777760007777700065744effffe4099fff90455555540000000055dddd660000000000000000000000000000000000000000000000000000000000000000
5777777055657770674545404422224400dddd00445554540000000055dddd660000000000000000000000000000000000000000000000000000000000000000
07777770075777700457546004f22f4000fddf00454454440090007055dddd660000000000000000000000000000000000000000000000000000000000000000
077777700777777044764670044cc440000440004444445439a907a7551111d60000000000000000000000000000000000000000000000000000000000000000
707070707070707060606060004cc400000ff0004444444403900b7b5111111d0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004444440555555555444445500067000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004ffffff49ffffff94444445500567000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004f3fff349f3fff394444454400566700000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004effffe4099fff904444444405566700000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000442222f400ddddf04445444405d66670000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004f2244000fdd0004455444455d66670000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000044cc440000440004444444455dd6667000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000c4c40000f0f00044444445555ddd66000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004444440555555550070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004ffffff49ffffff907a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000043fff3f493fff3f90070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004effffe4099fff900030000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004422224400dddd00003b000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004f22f4000fddf000b3000e000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000044cc4400004400000300eae00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000004cc400000ff00000300beb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004444440555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004ffffff49ffffff90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000043fff3f493fff3f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004effffe4099fff900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000442222f40fdddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004f22440000ddf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000044cc440000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000004c4c0000f0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004444440555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004ffffff49ffffff90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000043fff3f493fff3f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004effffe4099fff900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004f22224400ddddf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004422f4000fdd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000044cc440000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000c4c400000f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3500001600000008000000000016080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050500000505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606150600002525151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001d00000000000000000000000000000000000000000000000000405007050090500c0500c0500905007050070500a0500d0500a050050500000000000000000000000000000000000000000000000000000000
