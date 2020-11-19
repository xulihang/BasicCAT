package com.xulihang;

import org.fxmisc.richtext.CodeArea;

import javafx.scene.input.InputMethodEvent;
import javafx.scene.input.InputMethodTextRun;

public class Setup {
	private int imlength;
	private int imstart;

	public void setOnInputMethodTextChanged(CodeArea area){
		area.setOnInputMethodTextChanged(event -> {
            handleInputMethodEvent(event,area);
        });
	}
	
	public int getimlength(){
		return imlength;
	}
	
	public void handleInputMethodEvent(InputMethodEvent event,CodeArea area) {
	        if (area.isEditable()  && !area.isDisabled()) {

	            // remove previous input method text (if any) or selected text
	            if (imlength != 0) {
	                //removeHighlight(imattrs);
	                //imattrs.clear();
	                area.selectRange(imstart, imstart + imlength);
	            }

	            // Insert committed text
	            if (event.getCommitted().length() != 0) {
	                String committed = event.getCommitted();
	                area.replaceText(area.getSelection(), committed);
	            }

	            // Replace composed text
	            imstart = area.getSelection().getStart();
	            StringBuilder composed = new StringBuilder();
	            for (InputMethodTextRun run : event.getComposed()) {
	                composed.append(run.getText());
	            }
	            area.replaceText(area.getSelection(), composed.toString());
	            imlength = composed.length();
	            if (imlength != 0) {
	                int pos = imstart;
	                for (InputMethodTextRun run : event.getComposed()) {
	                    int endPos = pos + run.getText().length();
	                    //createInputMethodAttributes(run.getHighlight(), pos, endPos);
	                    pos = endPos;
	                }
	                //addHighlight(imattrs, imstart);

	                // Set caret position in composed text
	                int caretPos = event.getCaretPosition();
	                if (caretPos >= 0 && caretPos < imlength) {
	                	area.selectRange(imstart + caretPos, imstart + caretPos);
	                }
	            }
	        }
	    }
}
