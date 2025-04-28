CREATE TRIGGER trbd_happies
BEFORE DELETE ON happies
FOR EACH ROW
EXECUTE FUNCTION tr_prevent_deletion();
