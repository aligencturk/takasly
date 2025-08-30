#!/bin/bash

# Takasly App Sürüm Güncelleme Scripti
# Kullanım: ./version_bump.sh [major|minor|patch|build]

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Mevcut sürüm bilgileri
CURRENT_VERSION_NAME="1.0.0"
CURRENT_VERSION_CODE=31

# Sürüm parçalarını ayır
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION_NAME"
CURRENT_MAJOR=${VERSION_PARTS[0]}
CURRENT_MINOR=${VERSION_PARTS[1]}
CURRENT_PATCH=${VERSION_PARTS[2]}

echo -e "${BLUE}🔄 Takasly App Sürüm Güncelleme${NC}"
echo -e "${YELLOW}Mevcut Sürüm: ${CURRENT_VERSION_NAME} (Build: ${CURRENT_VERSION_CODE})${NC}"

if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Hata: Sürüm tipi belirtilmedi!${NC}"
    echo -e "Kullanım: $0 [major|minor|patch|build]"
    echo -e "  major: Ana sürüm (1.0.0 -> 2.0.0)"
    echo -e "  minor: Alt sürüm (1.0.0 -> 1.1.0)"
    echo -e "  patch: Yama sürüm (1.0.0 -> 1.0.1)"
    echo -e "  build: Build numarası (31 -> 32)"
    exit 1
fi

VERSION_TYPE=$1
NEW_VERSION_NAME=""
NEW_VERSION_CODE=$CURRENT_VERSION_CODE

case $VERSION_TYPE in
    "major")
        NEW_MAJOR=$((CURRENT_MAJOR + 1))
        NEW_VERSION_NAME="${NEW_MAJOR}.0.0"
        NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
        echo -e "${GREEN}🚀 Ana sürüm güncelleniyor: ${CURRENT_VERSION_NAME} -> ${NEW_VERSION_NAME}${NC}"
        ;;
    "minor")
        NEW_MINOR=$((CURRENT_MINOR + 1))
        NEW_VERSION_NAME="${CURRENT_MAJOR}.${NEW_MINOR}.0"
        NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
        echo -e "${GREEN}📈 Alt sürüm güncelleniyor: ${CURRENT_VERSION_NAME} -> ${NEW_VERSION_NAME}${NC}"
        ;;
    "patch")
        NEW_PATCH=$((CURRENT_PATCH + 1))
        NEW_VERSION_NAME="${CURRENT_MAJOR}.${CURRENT_MINOR}.${NEW_PATCH}"
        NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
        echo -e "${GREEN}🔧 Yama sürüm güncelleniyor: ${CURRENT_VERSION_NAME} -> ${NEW_VERSION_NAME}${NC}"
        ;;
    "build")
        NEW_VERSION_NAME=$CURRENT_VERSION_NAME
        NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
        echo -e "${GREEN}🔨 Build numarası güncelleniyor: ${CURRENT_VERSION_CODE} -> ${NEW_VERSION_CODE}${NC}"
        ;;
    *)
        echo -e "${RED}❌ Hata: Geçersiz sürüm tipi: ${VERSION_TYPE}${NC}"
        echo -e "Geçerli tipler: major, minor, patch, build"
        exit 1
        ;;
esac

echo -e "${YELLOW}Yeni Sürüm: ${NEW_VERSION_NAME} (Build: ${NEW_VERSION_CODE})${NC}"

# Android build.gradle.kts güncelle
echo -e "${BLUE}📱 Android sürüm güncelleniyor...${NC}"
sed -i '' "s/versionCode = [0-9]*/versionCode = ${NEW_VERSION_CODE}/" android/app/build.gradle.kts
sed -i '' "s/versionName = \"[^\"]*\"/versionName = \"${NEW_VERSION_NAME}\"/" android/app/build.gradle.kts

# iOS project.pbxproj güncelle
echo -e "${BLUE}🍎 iOS sürüm güncelleniyor...${NC}"
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*/CURRENT_PROJECT_VERSION = ${NEW_VERSION_CODE}/" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/MARKETING_VERSION = [0-9.]*/MARKETING_VERSION = ${NEW_VERSION_NAME}/" ios/Runner.xcodeproj/project.pbxproj

# macOS project.pbxproj güncelle (eğer varsa)
if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
    echo -e "${BLUE}🖥️  macOS sürüm güncelleniyor...${NC}"
    sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*/CURRENT_PROJECT_VERSION = ${NEW_VERSION_CODE}/" macos/Runner.xcodeproj/project.pbxproj
    sed -i '' "s/MARKETING_VERSION = [0-9.]*/MARKETING_VERSION = ${NEW_VERSION_NAME}/" macos/Runner.xcodeproj/project.pbxproj
fi

# Sürüm bilgilerini güncelle
echo -e "${BLUE}📝 Sürüm bilgileri güncelleniyor...${NC}"
echo "# Takasly App Sürüm Bilgileri" > VERSION_INFO.md
echo "Son güncelleme: $(date)" >> VERSION_INFO.md
echo "Sürüm: ${NEW_VERSION_NAME}" >> VERSION_INFO.md
echo "Build: ${NEW_VERSION_CODE}" >> VERSION_INFO.md
echo "Platform: Android, iOS, macOS" >> VERSION_INFO.md

echo -e "${GREEN}✅ Sürüm başarıyla güncellendi!${NC}"
echo -e "${YELLOW}📋 Güncellenen dosyalar:${NC}"
echo -e "  • android/app/build.gradle.kts"
echo -e "  • ios/Runner.xcodeproj/project.pbxproj"
if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
    echo -e "  • macos/Runner.xcodeproj/project.pbxproj"
fi
echo -e "  • VERSION_INFO.md"

echo -e "${BLUE}💡 Sonraki adımlar:${NC}"
echo -e "  1. Değişiklikleri commit edin: git add . && git commit -m \"Bump version to ${NEW_VERSION_NAME}+${NEW_VERSION_CODE}\""
echo -e "  2. Tag oluşturun: git tag v${NEW_VERSION_NAME}+${NEW_VERSION_CODE}"
echo -e "  3. Build alın: flutter clean && flutter build apk --release"
echo -e "  4. iOS için Xcode'da Archive yapın"

echo -e "${GREEN}🎉 İşlem tamamlandı!${NC}"
