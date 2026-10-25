package dev.handy.macro;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Kleines Eingabefenster für den Auftrag ("Das hier ist …, mache …"). */
public class TaskActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setFinishOnTouchOutside(true);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(pad, pad, pad, pad);

        TextView hint = new TextView(this);
        hint.setText("Auftrag für die App im Vordergrund");
        hint.setTextSize(16);
        root.addView(hint);

        EditText input = new EditText(this);
        input.setHint("z. B. spiel 40 Züge");
        input.setText(Termux.task(this));
        input.setSelection(input.getText().length());
        input.setSingleLine(false);
        input.setMaxLines(4);
        root.addView(input, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.END);

        Button cancel = new Button(this);
        cancel.setText("Abbrechen");
        cancel.setOnClickListener(v -> finish());
        row.addView(cancel);

        Button save = new Button(this);
        save.setText("Speichern");
        save.setOnClickListener(v -> {
            Termux.saveTask(this, input.getText().toString().trim());
            finish();
        });
        row.addView(save);

        Button start = new Button(this);
        start.setText("Starten");
        start.setOnClickListener(v -> {
            String t = input.getText().toString().trim();
            Termux.saveTask(this, t);
            finish();
            Termux.start(getApplicationContext(), t);
        });
        row.addView(start);

        root.addView(row);
        setContentView(root);
    }
}
