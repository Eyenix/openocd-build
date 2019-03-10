# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------

function do_openocd()
{

  if true
  then

    download_openocd

    (
      xbb_activate
      xbb_activate_this

      cd "${WORK_FOLDER_PATH}/${OPENOCD_SRC_FOLDER_NAME}"
      if [ ! -d "autom4te.cache" ]
      then
        ./bootstrap
      fi

      mkdir -p "${BUILD_FOLDER_PATH}/${OPENOCD_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${OPENOCD_FOLDER_NAME}"

      export JAYLINK_CFLAGS='${EXTRA_CFLAGS} -fvisibility=hidden'

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then

        # --enable-minidriver-dummy -> configure error
        # --enable-zy1000 -> netinet/tcp.h: No such file or directory

        # --enable-openjtag_ftdi -> --enable-openjtag
        # --enable-presto_libftdi -> --enable-presto
        # --enable-usb_blaster_libftdi -> --enable-usb_blaster

        export OUTPUT_DIR="${BUILD_FOLDER_PATH}"
        
        export CFLAGS="${EXTRA_CXXFLAGS} -Wno-pointer-to-int-cast" 
        export CXXFLAGS="${EXTRA_CXXFLAGS}" 
        export LDFLAGS="${EXTRA_LDFLAGS} -static"

        AMTJTAGACCEL="--enable-amtjtagaccel"
        # --enable-buspirate -> not supported on mingw
        BUSPIRATE="--disable-buspirate"
        GW18012="--enable-gw16012"
        PARPORT="--enable-parport"
        PARPORT_GIVEIO="--enable-parport-giveio"
        # --enable-sysfsgpio -> available only on Linux
        SYSFSGPIO="--disable-sysfsgpio"

      elif [ "${TARGET_PLATFORM}" == "linux" ]
      then

        # --enable-minidriver-dummy -> configure error

        # --enable-openjtag_ftdi -> --enable-openjtag
        # --enable-presto_libftdi -> --enable-presto
        # --enable-usb_blaster_libftdi -> --enable-usb_blaster

        export CFLAGS="${EXTRA_CFLAGS} -Wno-format-truncation -Wno-format-overflow"
        export CXXFLAGS="${EXTRA_CXXFLAGS}"
        export LDFLAGS="${EXTRA_LDFLAGS}" 
        export LIBS="-lpthread -lrt -ludev"

        AMTJTAGACCEL="--enable-amtjtagaccel"
        BUSPIRATE="--enable-buspirate"
        GW18012="--enable-gw16012"
        PARPORT="--enable-parport"
        PARPORT_GIVEIO="--enable-parport-giveio"
        SYSFSGPIO="--enable-sysfsgpio"

      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then

        # --enable-minidriver-dummy -> configure error

        # --enable-openjtag_ftdi -> --enable-openjtag
        # --enable-presto_libftdi -> --enable-presto
        # --enable-usb_blaster_libftdi -> --enable-usb_blaster

        export CFLAGS="${EXTRA_CFLAGS}"
        export CXXFLAGS="${EXTRA_CXXFLAGS}"
        export LDFLAGS="${EXTRA_LDFLAGS}"
        export LIBS="-lobjc"

        # --enable-amtjtagaccel -> 'sys/io.h' file not found
        AMTJTAGACCEL="--disable-amtjtagaccel"
        BUSPIRATE="--enable-buspirate"
        # --enable-gw16012 -> 'sys/io.h' file not found
        GW18012="--disable-gw16012"
        PARPORT="--disable-parport"
        PARPORT_GIVEIO="--disable-parport-giveio"
        # --enable-sysfsgpio -> available only on Linux
        SYSFSGPIO="--disable-sysfsgpio"

      else

        echo "Unsupported target platorm ${TARGET_PLATFORM}."
        exit 1

      fi

      if [ ! -f "config.status" ]
      then

        # May be required for repetitive builds, because this is an executable built 
        # in place and using one for a different architecture may not be a good idea.
        rm -rfv "${WORK_FOLDER_PATH}/${OPENOCD_SRC_FOLDER_NAME}/jimtcl/autosetup/jimsh0"

        echo
        echo "Running openocd configure..."
      
        (
          bash "${WORK_FOLDER_PATH}/${OPENOCD_SRC_FOLDER_NAME}/configure" --help

          bash ${DEBUG} "${WORK_FOLDER_PATH}/${OPENOCD_SRC_FOLDER_NAME}/configure" \
            --prefix="${APP_PREFIX}"  \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --datarootdir="${INSTALL_FOLDER_PATH}" \
            --localedir="${APP_PREFIX}/share/locale"  \
            --mandir="${APP_PREFIX_DOC}/man"  \
            --pdfdir="${APP_PREFIX_DOC}/pdf"  \
            --infodir="${APP_PREFIX_DOC}/info" \
            --docdir="${APP_PREFIX_DOC}"  \
            \
            --disable-wextra \
            --disable-werror \
            --enable-dependency-tracking \
            \
            --enable-branding="${BRANDING}" \
            \
            --enable-aice \
            ${AMTJTAGACCEL} \
            --enable-armjtagew \
            --enable-at91rm9200 \
            --enable-bcm2835gpio \
            ${BUSPIRATE} \
            --enable-cmsis-dap \
            --enable-dummy \
            --enable-ep93xx \
            --enable-ftdi \
            ${GW18012} \
            --disable-ioutil \
            --enable-jlink \
            --enable-jtag_vpi \
            --disable-minidriver-dummy \
            --disable-oocd_trace \
            --enable-opendous \
            --enable-openjtag \
            --enable-osbdm \
            ${PARPORT} \
            --disable-parport-ppdev \
            ${PARPORT_GIVEIO} \
            --enable-presto \
            --enable-remote-bitbang \
            --enable-riscv \
            --enable-rlink \
            --enable-stlink \
            ${SYSFSGPIO} \
            --enable-ti-icdi \
            --enable-ulink \
            --enable-usb-blaster \
            --enable-usb_blaster_2 \
            --enable-usbprog \
            --enable-vsllink \
            --disable-zy1000-master \
            --disable-zy1000 \

        ) 2>&1 | tee "${INSTALL_FOLDER_PATH}/configure-openocd-output.txt"
        cp "config.log" "${INSTALL_FOLDER_PATH}/config-openocd-log.txt"

      fi

      echo
      echo "Running openocd make..."
      
      (
        make ${JOBS} bindir="bin" pkgdatadir=""
        if [ "${WITH_STRIP}" == "y" ]
        then
          make install-strip
        else
          make install  
        fi

        if [ "${WITH_PDF}" == "y" ]
        then
          make ${JOBS} bindir="bin" pkgdatadir="" pdf 
          make install-pdf
        fi

        if [ "${WITH_HTML}" == "y" ]
        then
          make ${JOBS} bindir="bin" pkgdatadir="" html
          make install-html
        fi

        if [ "${TARGET_PLATFORM}" == "linux" ]
        then
          # Workaround to Docker error on 32-bit image:
          # stat: Value too large for defined data type
          rm -rf /tmp/openocd
          cp "${APP_PREFIX}/bin/openocd" /tmp/openocd
          patchelf --set-rpath '$ORIGIN' /tmp/openocd
          cp /tmp/openocd "${APP_PREFIX}/bin/openocd"

          copy_linux_system_so libudev
        elif [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          change_dylib "libgcc_s.1.dylib" "${APP_PREFIX}/bin/openocd"
        elif [ "${TARGET_PLATFORM}" == "win32" ]
        then
          # For unknown reasons, openocd still has a reference to libusb0.dll,
          # although everything should have been compiled as static.
          cp -v "${LIBS_INSTALL_FOLDER_PATH}/bin/libusb0.dll" \
            "${APP_PREFIX}/bin"
        fi

      ) 2>&1 | tee "${INSTALL_FOLDER_PATH}/make-openocd-output.txt"
    )

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      local wsl_path=$(which wsl.exe)
      if [ ! -z "${wsl_path}" ]
      then
        echo
        "${APP_PREFIX}/bin/openocd.exe" --version
      else 
        local wine_path=$(which wine)
        if [ ! -z "${wine_path}" ]
        then
          echo
          wine "${APP_PREFIX}/bin/openocd.exe" --version
        else
          echo
          echo "Install wine if you want to run the .exe binaries on Linux."
        fi
      fi
    else
      echo
      "${APP_PREFIX}/bin/openocd" --version
    fi

  fi
}

# -----------------------------------------------------------------------------

function copy_gme_files()
{
  rm -rf "${APP_PREFIX}/${DISTRO_LC_NAME}"
  mkdir -p "${APP_PREFIX}/${DISTRO_LC_NAME}"

  echo
  echo "Copying license files..."

  copy_license \
    "${SOURCES_FOLDER_PATH}/${LIBUSB1_SRC_FOLDER_NAME}" \
    "${LIBUSB1_FOLDER_NAME}"

  if [ "${TARGET_PLATFORM}" != "win32" ]
  then
    copy_license \
      "${SOURCES_FOLDER_PATH}/${LIBUSB0_SRC_FOLDER_NAME}" \
      "${LIBUSB0_FOLDER_NAME}"
  else
    copy_license \
      "${SOURCES_FOLDER_PATH}/${LIBUSB_W32_SRC_FOLDER_NAME}" \
      "${LIBUSB_W32_FOLDER_NAME}"
  fi

  copy_license \
    "${SOURCES_FOLDER_PATH}/${LIBFTDI_SRC_FOLDER_NAME}" \
    "${LIBFTDI_FOLDER_NAME}"
  copy_license \
    "${SOURCES_FOLDER_PATH}/${LIBICONV_SRC_FOLDER_NAME}" \
    "${LIBICONV_FOLDER_NAME}"

  copy_license \
    "${WORK_FOLDER_PATH}/${OPENOCD_SRC_FOLDER_NAME}" \
    "${OPENOCD_FOLDER_NAME}"

  copy_build_files

  echo
  echo "Copying GME files..."

  cd "${WORK_FOLDER_PATH}/build.git"
  /usr/bin/install -v -c -m 644 "${README_OUT_FILE_NAME}" \
    "${APP_PREFIX}/README.md"
}
