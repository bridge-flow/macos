.PHONY: test check build mocks assets package run

test:
	swift run BridgeFlowCoreTests

check:
	swift build

build:
	swift build

mocks:
	@echo "No mocks required for the current MVP"

assets:
	swift script/generate_assets.swift

package:
	./script/build_and_run.sh --package

run:
	./script/build_and_run.sh
