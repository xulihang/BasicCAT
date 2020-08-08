package com.xulihang;

import java.util.Optional;

import org.fxmisc.richtext.CodeArea;

import javafx.geometry.Bounds;
import javafx.geometry.Point2D;
import javafx.scene.input.InputMethodRequests;

public class InputMethodRequestsObject implements InputMethodRequests {

	public CodeArea area;

	public void setArea(CodeArea a){
		area=a;
	}

	@Override
	public
	String getSelectedText() {
        return "";
    }
    @Override
	public
    int getLocationOffset(int x, int y) {
        return 0;
    }
    @Override
	public
    void cancelLatestCommittedText() {

    }
    @Override
	public
    Point2D getTextLocation(int offset) {
    	// a very rough example, only tested under macOS
        Optional<Bounds> caretPositionBounds = area.getCaretBounds();
        if (caretPositionBounds.isPresent()) {
            Bounds bounds = caretPositionBounds.get();
            return new Point2D(bounds.getMaxX() - 5, bounds.getMaxY());
        }

        throw new NullPointerException();
    }
}