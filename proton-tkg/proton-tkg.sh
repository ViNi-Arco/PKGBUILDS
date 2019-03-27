#!/bin/bash

# Created by: Tk-Glitch <ti3nou at gmail dot com>

# This script creates Steamplay compatible wine builds based on wine-tkg-git and additional proton patches and libraries.
# It is not standalone and can be considered an addon to wine-tkg-git PKGBUILD and patchsets.

_nowhere=$PWD
_wine_tkg_git_path=${_nowhere}/../wine-tkg-git # Change to wine-tkg-git path if needed

echo '       .---.`               `.---.       '
echo '    `/syhhhyso-           -osyhhhys/`    '
echo '   .syNMdhNNhss/``.---.``/sshNNhdMNys.   '
echo '   +sdMh.`+MNsssssssssssssssNM+`.hMds+   '
echo '   :syNNdhNNhssssssssssssssshNNhdNNys:   '
echo '    /ssyhhhysssssssssssssssssyhhhyss/    '
echo '    .ossssssssssssssssssssssssssssso.    '
echo '   :sssssssssssssssssssssssssssssssss:   '
echo '  /sssssssssssssssssssssssssssssssssss/  '
echo ' :sssssssssssssoosssssssoosssssssssssss: '
echo ' osssssssssssssoosssssssoossssssssssssso '
echo ' osssssssssssyyyyhhhhhhhyyyyssssssssssso '
echo ' /yyyyyyhhdmmmmNNNNNNNNNNNmmmmdhhyyyyyy/ '
echo '  smmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmms  '
echo '   /dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd/   '
echo '    `:sdNNNNNNNNNNNNNNNNNNNNNNNNNds:`    '
echo '       `-+shdNNNNNNNNNNNNNNNdhs+-`       '
echo '             `.-:///////:-.`             '
echo ' ______              __                      __   __          '
echo '|   __ \.----.-----.|  |_.-----.-----.______|  |_|  |--.-----.'
echo '|    __/|   _|  _  ||   _|  _  |     |______|   _|    <|  _  |'
echo '|___|   |__| |_____||____|_____|__|__|      |____|__|__|___  |'
echo '                                                       |_____|'
echo ''
echo 'Also known as "Some kind of build wrapper for wine-tkg-git"'
echo ''

# We'll need a token to register to wine-tkg-git - keep one for us to steal wine-tkg-git options later
echo "_proton_tkg_path='${_nowhere}'" > proton_tkg_token && cp proton_tkg_token "$_wine_tkg_git_path"/

# Now let's build
cd "$_wine_tkg_git_path"
makepkg -s

# Wine-tkg-git has injected versioning and settings in the token for us, so get the values back
source $_nowhere/proton_tkg_token

# Copy the resulting package in here to begin our work
if [ -e "$_proton_pkgdest"/proton_dist*.tar* ]; then
  mv "$_proton_pkgdest"/proton_dist*.tar* $_nowhere/

  cd $_nowhere

  # Create required dirs
  mkdir -p $HOME/.steam/root/compatibilitytools.d
  mkdir proton_dist_tmp
  mkdir proton_tkg_$_protontkg_version
  mkdir -p proton_template/share/fonts

  # Extract our custom package
  tar -xvf proton_dist*.tar* -C ./proton_dist_tmp >/dev/null 2>&1
  rm proton_dist*.tar*

  # Liberation Fonts
  rm -f proton_template/share/fonts/*
  git clone https://github.com/liberationfonts/liberation-fonts.git # It'll complain the path already exists on subsequent builds
  cd liberation-fonts
  git reset --hard HEAD
  git clean -xdf
  patch -Np1 < $_nowhere/'LiberationMono-Regular.patch'
  make
  cp -rv liberation-fonts-ttf*/Liberation{Sans-Regular,Sans-Bold,Serif-Regular,Mono-Regular}.ttf $_nowhere/proton_template/share/fonts/
  cd $_nowhere

  # Grab share template and inject version
  echo "1552061114 proton-tkg-$_protontkg_version" > proton_dist_tmp/version && cp -r proton_template/share/* proton_dist_tmp/share/

  # Clone Proton tree as we need to build lsteamclient libs
  git clone https://github.com/ValveSoftware/Proton # It'll complain the path already exists on subsequent builds
  cd Proton
  git reset --hard HEAD
  git clean -xdf

  export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt --dll"
  export CFLAGS="-O2 -g"
  export CXXFLAGS="-Wno-attributes -O2 -g" 
  
  mkdir -p build/lsteamclient.win64
  mkdir -p build/lsteamclient.win32

  cp -a lsteamclient/* build/lsteamclient.win64
  cp -a lsteamclient/* build/lsteamclient.win32

  cd build/lsteamclient.win64
  winemaker $WINEMAKERFLAGS -DSTEAM_API_EXPORTS .
  make -C $_nowhere/Proton/build/lsteamclient.win64 && strip lsteamclient.dll.so
  cd ../..

  cd build/lsteamclient.win32
  winemaker $WINEMAKERFLAGS --wine32 -DSTEAM_API_EXPORTS .
  make -e CC="winegcc -m32" CXX="wineg++ -m32" -C $_nowhere/Proton/build/lsteamclient.win32 && strip lsteamclient.dll.so
  cd $_nowhere

  # Inject lsteamclient libs in our wine-tkg-git build
  cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.so proton_dist_tmp/lib64/wine/
  cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.so proton_dist_tmp/lib/wine/

  # If the token gave us _prebuilt_dxvk, try to build with it - See dir hierarchy below(or in readme) if you aren't building using dxvk-tools
  if [ "$_prebuilt_dxvk" == "true" ]; then
    if [ -d ./dxvk ]; then
      mkdir -p proton_dist_tmp/lib64/wine/dxvk && cp -v dxvk/x64/* proton_dist_tmp/lib64/wine/dxvk/
      mkdir -p proton_dist_tmp/lib/wine/dxvk && cp -v dxvk/x32/* proton_dist_tmp/lib/wine/dxvk/
      if [ "$_dxvk_dxgi" != "true" ]; then
        rm proton_dist_tmp/lib64/wine/dxvk/dxgi.dll
        rm proton_dist_tmp/lib/wine/dxvk/dxgi.dll
      fi
    else
      echo "Your config file is set up to include prebuilt DXVK, but you seem to be missing it."
    fi
  fi

  echo ''
  echo "Packaging..."

  # Package
  cd proton_dist_tmp && tar -zcf proton_dist.tar.gz bin/ include/ lib64/ lib/ share/ version && mv proton_dist.tar.gz ../proton_tkg_$_protontkg_version
  cd $_nowhere && rm -rf proton_dist_tmp

  # Grab conf template and inject version
  echo "1552061114 proton-tkg-$_protontkg_version" > proton_tkg_$_protontkg_version/version && cp proton_template/conf/* proton_tkg_$_protontkg_version/ && sed -i -e "s|TKGVERSION|$_protontkg_version|" ./proton_tkg_$_protontkg_version/compatibilitytool.vdf

  # Set Proton-tkg user_settings.py defaults
  if [ "$_proton_nvapi_disable" == "true" ]; then
    sed -i 's/.*PROTON_NVAPI_DISABLE.*/     "PROTON_NVAPI_DISABLE": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  else
    sed -i 's/.*PROTON_NVAPI_DISABLE.*/#    "PROTON_NVAPI_DISABLE": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  fi
  if [ "$_proton_winedbg_disable" == "true" ]; then
    sed -i 's/.*PROTON_WINEDBG_DISABLE.*/     "PROTON_WINEDBG_DISABLE": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  else
        sed -i 's/.*PROTON_WINEDBG_DISABLE.*/#    "PROTON_WINEDBG_DISABLE": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  fi
  if [ "$_proton_force_LAA" == "true" ]; then
    sed -i 's/.*PROTON_FORCE_LARGE_ADDRESS_AWARE.*/     "PROTON_FORCE_LARGE_ADDRESS_AWARE": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  else
    sed -i 's/.*PROTON_FORCE_LARGE_ADDRESS_AWARE.*/#    "PROTON_FORCE_LARGE_ADDRESS_AWARE": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  fi
  if [ "$_proton_pulse_lowlat" == "true" ]; then
    sed -i 's/.*PROTON_PULSE_LOWLATENCY.*/     "PROTON_PULSE_LOWLATENCY": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  else
    sed -i 's/.*PROTON_PULSE_LOWLATENCY.*/#    "PROTON_PULSE_LOWLATENCY": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  fi
  if [ "$_proton_dxvk_async" == "true" ]; then
    sed -i 's/.*PROTON_DXVK_ASYNC.*/     "PROTON_DXVK_ASYNC": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  else
    sed -i 's/.*PROTON_DXVK_ASYNC.*/#    "PROTON_DXVK_ASYNC": "1",/g' proton_tkg_$_protontkg_version/user_settings.py
  fi
  if [ -n "$_proton_dxvk_configfile" ]; then
    sed -i "s|.*DXVK_CONFIG_FILE.*|     \"DXVK_CONFIG_FILE\": \"${_proton_dxvk_configfile}\",|g" proton_tkg_$_protontkg_version/user_settings.py
  fi
  if [ -n "$_proton_dxvk_hud" ]; then
    sed -i "s|.*DXVK_HUD.*|     \"DXVK_HUD\": \"${_proton_dxvk_hud}\",|g" proton_tkg_$_protontkg_version/user_settings.py
  fi

  # Use the corresponding script depending on DXVK type
  if [ "$_prebuilt_dxvk" == "true" ]; then
    mv proton_tkg_$_protontkg_version/proton.prebuilt proton_tkg_$_protontkg_version/proton
  else
    mv proton_tkg_$_protontkg_version/proton.winelib proton_tkg_$_protontkg_version/proton
  fi

  # Nuke same version if exists before copying new build
  if [ -e $HOME/.steam/root/compatibilitytools.d/proton_tkg_$_protontkg_version ]; then
    rm -rf $HOME/.steam/root/compatibilitytools.d/proton_tkg_$_protontkg_version
  fi

  # Get rid of the token
  rm proton_tkg_token

  mv proton_tkg_$_protontkg_version $HOME/.steam/root/compatibilitytools.d/ && echo "" && echo "Proton-tkg build installed to $HOME/.steam/root/compatibilitytools.d/proton_tkg_$_protontkg_version"
else
  rm $_nowhere/proton_tkg_token
  echo "The required proton_dist package is missing! Wine-tkg-git compilation may have failed."
fi