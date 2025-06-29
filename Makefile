# Makefile for workout-plan project using Poetry

.PHONY: install run clean

init:
	pyenv install -s 3.11.9
	pyenv local 3.11.9
	poetry env use 3.11.9
	poetry install
	npm ci

install:
	poetry install

run:
	mkdir -p output
	poetry run python -m workout_exporter --input resources/BFX.Xceed.Global.OM.EN.pdf --output output/Bowflex_Workout_Booklet.pdf --yaml workouts.yaml

run-md:
	mkdir -p output
	poetry run python -m workout_exporter --input resources/BFX.Xceed.Global.OM.EN.pdf --output output/Bowflex_Workout_Booklet.pdf --yaml workouts.yaml --markdown resources/workout_plan.md

clean:
	rm -f output/Bowflex_Workout_Booklet.pdf
