#!/bin/zsh
# Builds dist/DieNoise-<version>-macOS.pkg: an unsigned installer where the user picks the formats
# (AU, VST3, CLAP).
#
#   tools/make_installer_mac.sh
#
# Plugins go to /Library/Audio/Plug-Ins/<format>.
set -euo pipefail

ROOT=${0:A:h:h}
cd "$ROOT"

VERSION=$(sed -n 's/^project(TheCalm VERSION \([0-9.]*\).*/\1/p' CMakeLists.txt)
[[ -n $VERSION ]] || { echo "could not read the version from CMakeLists.txt"; exit 1; }

cmake -B build -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build build --config Release -j8 --target TheCalm_AU TheCalm_VST3 TheCalm_CLAP >/dev/null

ARTEFACTS=build/TheCalm_artefacts/Release
WORK=build/installer
OUT=dist/DieNoise-$VERSION-macOS.pkg
rm -rf "$WORK"
mkdir -p "$WORK/packages" dist

# id | artefact | install location
COMPONENTS=(
    "au|AU/Die Noise.component|/Library/Audio/Plug-Ins/Components"
    "vst3|VST3/Die Noise.vst3|/Library/Audio/Plug-Ins/VST3"
    "clap|CLAP/Die Noise.clap|/Library/Audio/Plug-Ins/CLAP"
)

for entry in $COMPONENTS; do
    IFS='|' read -r id artefact location <<< "$entry"
    stage="$WORK/stage/$id"
    mkdir -p "$stage"
    ditto "$ARTEFACTS/$artefact" "$stage/${artefact:t}"
    # Without this, Installer may "relocate" the bundle onto an existing copy elsewhere on disk.
    pkgbuild --analyze --root "$stage" "$WORK/$id.plist" >/dev/null
    plutil -replace 0.BundleIsRelocatable -bool NO "$WORK/$id.plist"
    pkgbuild --root "$stage" --component-plist "$WORK/$id.plist" \
             --identifier "com.kingsdiehere.dienoise.$id" --version "$VERSION" \
             --install-location "$location" "$WORK/packages/$id.pkg" >/dev/null
done

cat > "$WORK/distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>Die Noise $VERSION</title>
    <organization>com.kingsdiehere</organization>
    <domains enable_localSystem="true"/>
    <options customize="always" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <welcome file="welcome.txt" mime-type="text/plain"/>
    <choices-outline>
        <line choice="au"/>
        <line choice="vst3"/>
        <line choice="clap"/>
    </choices-outline>
    <choice id="au" title="AU" description="Installs to /Library/Audio/Plug-Ins/Components." start_selected="true">
        <pkg-ref id="com.kingsdiehere.dienoise.au"/>
    </choice>
    <choice id="vst3" title="VST3" description="Installs to /Library/Audio/Plug-Ins/VST3." start_selected="true">
        <pkg-ref id="com.kingsdiehere.dienoise.vst3"/>
    </choice>
    <choice id="clap" title="CLAP" description="Installs to /Library/Audio/Plug-Ins/CLAP." start_selected="true">
        <pkg-ref id="com.kingsdiehere.dienoise.clap"/>
    </choice>
    <pkg-ref id="com.kingsdiehere.dienoise.au" version="$VERSION">au.pkg</pkg-ref>
    <pkg-ref id="com.kingsdiehere.dienoise.vst3" version="$VERSION">vst3.pkg</pkg-ref>
    <pkg-ref id="com.kingsdiehere.dienoise.clap" version="$VERSION">clap.pkg</pkg-ref>
</installer-gui-script>
EOF

mkdir -p "$WORK/resources"
cat > "$WORK/resources/welcome.txt" <<EOF
Die Noise $VERSION by Kings Die Here

An octave pedal that ruins everything.

Click "Customize" on the next step to choose which formats to install.
After installing, rescan plug-ins in your DAW if Die Noise does not show up.

This installer is not signed by Apple. If macOS blocks it, open
System Settings > Privacy & Security and click "Open Anyway".
EOF

productbuild --distribution "$WORK/distribution.xml" --package-path "$WORK/packages" \
             --resources "$WORK/resources" "$OUT" >/dev/null
echo "$OUT"
