import org.junit.Test;

import static org.junit.Assert.assertTrue;

/**
 * @author Alexey Zhytnik
 * @since 11.08.2016
 */
public class SimpleTest {

    @Test
    public void ok(){
        SimpleClass s = new SimpleClass();
        s.setValue("new value");
        assertTrue(s.getValue().equals("new value"));
    }

    @Test
    public void fail(){
        assertTrue(true);
    }
}
